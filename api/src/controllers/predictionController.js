const { supabaseAdmin } = require('../config/supabase');

async function insertCashflowPrediction(req, res) {
  const { business_id, risk_level, days_until_broke, confidence_score, summary } = req.body;
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
  const { business_id, critical_items, warning_items, total_value_at_risk, summary } = req.body;
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
