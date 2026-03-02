const { supabaseAdmin } = require('../config/supabase');

function pickFirstDefined(...values) {
  for (const value of values) {
    if (value !== undefined && value !== null) return value;
  }
  return undefined;
}

function toNumber(value, fallback = 0) {
  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toInteger(value, fallback = 0) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeRiskLevel(value) {
  const raw = String(value || '').trim().toLowerCase();
  if (!raw) return 'medium';
  if (['low', 'medium', 'high', 'critical'].includes(raw)) return raw;
  if (raw.includes('crit')) return 'critical';
  if (raw.includes('high')) return 'high';
  if (raw.includes('low')) return 'low';
  return 'medium';
}

function normalizeConfidence(value) {
  let confidence = toNumber(value, 0.5);
  if (confidence > 1 && confidence <= 100) {
    confidence = confidence / 100;
  }
  if (confidence < 0) confidence = 0;
  if (confidence > 1) confidence = 1;
  return Number.parseFloat(confidence.toFixed(4));
}

async function insertCashflowPrediction(req, res) {
  const localPrediction = req.body.local_prediction || {};
  const backendResponse = req.body.backend_response || {};
  const modelResponse = req.body.model_response || {};

  const business_id = pickFirstDefined(
    req.body.business_id,
    req.body.businessId,
    localPrediction.business_id,
    modelResponse.business_id,
    backendResponse.business_id
  );

  const risk_level = normalizeRiskLevel(
    pickFirstDefined(
      req.body.risk_level,
      req.body.riskLevel,
      localPrediction.risk_level,
      localPrediction.risk,
      localPrediction.riskLevel,
      modelResponse.risk_level,
      backendResponse.risk_level
    )
  );

  const days_until_broke = toInteger(
    pickFirstDefined(
      req.body.days_until_broke,
      req.body.daysUntilBroke,
      localPrediction.days_until_broke,
      localPrediction.runway_days,
      localPrediction.days,
      modelResponse.days_until_broke,
      backendResponse.days_until_broke
    ),
    0
  );

  const confidence_score = normalizeConfidence(
    pickFirstDefined(
      req.body.confidence_score,
      req.body.confidenceScore,
      localPrediction.confidence_score,
      localPrediction.confidence,
      localPrediction.probability,
      modelResponse.confidence_score,
      backendResponse.confidence_score
    )
  );

  const summary = pickFirstDefined(
    req.body.summary,
    req.body.local_summary,
    req.body.input_summary,
    localPrediction.summary
  );

  if (!business_id) return res.status(400).json({ error: 'business_id is required' });

  try {
    let { data, error } = await supabaseAdmin
      .from('cashflow_predictions')
      .insert({ business_id, risk_level, days_until_broke, confidence_score, summary: summary || null })
      .select()
      .single();

    if (error && String(error.message || '').toLowerCase().includes('summary')) {
      ({ data, error } = await supabaseAdmin
        .from('cashflow_predictions')
        .insert({ business_id, risk_level, days_until_broke, confidence_score })
        .select()
        .single());
    }

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ prediction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function insertInventoryPrediction(req, res) {
  const localResult = req.body.local_result || {};
  const backendResponse = req.body.backend_response || {};
  const modelResponse = req.body.model_response || {};

  const business_id = pickFirstDefined(
    req.body.business_id,
    req.body.businessId,
    localResult.business_id,
    modelResponse.business_id,
    backendResponse.business_id
  );
  const critical_items = toInteger(
    pickFirstDefined(
      req.body.critical_items,
      req.body.criticalItems,
      localResult.critical_items,
      modelResponse.critical_items,
      backendResponse.critical_items
    ),
    0
  );
  const warning_items = toInteger(
    pickFirstDefined(
      req.body.warning_items,
      req.body.warningItems,
      localResult.warning_items,
      modelResponse.warning_items,
      backendResponse.warning_items
    ),
    0
  );
  const total_value_at_risk = toNumber(
    pickFirstDefined(
      req.body.total_value_at_risk,
      req.body.totalValueAtRisk,
      localResult.total_value_at_risk,
      modelResponse.total_value_at_risk,
      backendResponse.total_value_at_risk
    ),
    0
  );
  const summary = pickFirstDefined(
    req.body.summary,
    req.body.local_summary,
    req.body.input_summary,
    localResult.summary
  );

  if (!business_id) return res.status(400).json({ error: 'business_id is required' });

  try {
    let { data, error } = await supabaseAdmin
      .from('inventory_predictions')
      .insert({ business_id, critical_items, warning_items, total_value_at_risk, summary: summary || null })
      .select()
      .single();

    if (error && String(error.message || '').toLowerCase().includes('summary')) {
      ({ data, error } = await supabaseAdmin
        .from('inventory_predictions')
        .insert({ business_id, critical_items, warning_items, total_value_at_risk })
        .select()
        .single());
    }

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ prediction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getLatestPredictions(req, res) {
  const business_id = req.profile.business_id;
  try {
    const [cashflow, inventory] = await Promise.all([
      supabaseAdmin
        .from('cashflow_predictions')
        .select('*')
        .eq('business_id', business_id)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle(),
      supabaseAdmin
        .from('inventory_predictions')
        .select('*')
        .eq('business_id', business_id)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()
    ]);

    return res.status(200).json({
      cashflow_prediction: cashflow.data || null,
      inventory_prediction: inventory.data || null
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function insertAnomaly(req, res) {
  const {
    business_id,
    expense_id,
    transaction_id,
    anomaly_level,
    z_score,
    deviation_percentage,
    reason,
    amount,
    category
  } = req.body;

  try {
    let data;
    let error;

    // New-schema shape
    ({ data, error } = await supabaseAdmin
      .from('expense_anomalies')
      .insert({
        business_id: business_id || null,
        expense_id: expense_id || null,
        anomaly_level,
        z_score,
        deviation_percentage,
        reason: reason || null,
        amount: amount || null,
        category: category || null
      })
      .select()
      .single());

    // Old-schema fallback
    if (error) {
      ({ data, error } = await supabaseAdmin
        .from('expense_anomalies')
        .insert({
          transaction_id: transaction_id || expense_id || null,
          anomaly_level,
          z_score,
          deviation_percentage
        })
        .select()
        .single());
    }

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ anomaly: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getAnomalies(req, res) {
  const business_id = req.profile.business_id;
  const { limit = 20, offset = 0 } = req.query;

  try {
    let { data, error, count } = await supabaseAdmin
      .from('expense_anomalies')
      .select('*, expenses(*)', { count: 'exact' })
      .eq('business_id', business_id)
      .order('created_at', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    // Old-schema fallback via transactions join
    if (error) {
      ({ data, error, count } = await supabaseAdmin
        .from('expense_anomalies')
        .select('*, transactions!inner(*)', { count: 'exact' })
        .eq('transactions.business_id', business_id)
        .order('created_at', { ascending: false })
        .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1));
    }

    if (error) return res.status(400).json({ error: error.message });

    const anomalies = (data || []).map((row) => ({
      ...row,
      transaction_id: row.transaction_id || row.expense_id || '',
      message: row.message || row.reason || `Unusual ${row.anomaly_level || 'low'} anomaly detected`
    }));

    return res.status(200).json({ anomalies, total: count || 0 });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  insertCashflowPrediction,
  insertInventoryPrediction,
  getLatestPredictions,
  insertAnomaly,
  getAnomalies
};
