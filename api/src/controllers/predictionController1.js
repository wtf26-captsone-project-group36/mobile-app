/*const { supabaseAdmin } = require('../config/supabase');

// =============================================
// INSERT cashflow prediction — called by FastAPI AI server
// No auth required — internal AI service call
//
// Expected body from FastAPI backend_client.py:
// { business_id, risk_level, days_until_broke, confidence_score, summary }
// =============================================
async function insertCashflowPrediction(req, res) {
  const { business_id, risk_level, days_until_broke, confidence_score, summary } = req.body;

  if (!business_id) return res.status(400).json({ error: 'business_id is required' });

  const validRiskLevels = ['low', 'medium', 'high', 'critical', 'unknown'];
  const resolvedRiskLevel = (risk_level && validRiskLevels.includes(risk_level))
    ? risk_level
    : 'unknown';

  try {
    const { data, error } = await supabaseAdmin
      .from('cashflow_predictions')
      .insert({
        business_id,
        risk_level: resolvedRiskLevel,
        days_until_broke: days_until_broke || null,
        confidence_score: confidence_score || null
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ message: 'Cashflow prediction stored', prediction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// INSERT inventory prediction — called by FastAPI AI server
// No auth required — internal AI service call
//
// Expected body from FastAPI backend_client.py:
// { business_id, critical_items, warning_items, total_value_at_risk, summary }
// =============================================
async function insertInventoryPrediction(req, res) {
  const { business_id, critical_items, warning_items, total_value_at_risk, summary } = req.body;

  if (!business_id) return res.status(400).json({ error: 'business_id is required' });

  try {
    const { data, error } = await supabaseAdmin
      .from('inventory_predictions')
      .insert({
        business_id,
        critical_items: critical_items || 0,
        warning_items: warning_items || 0,
        total_value_at_risk: total_value_at_risk || 0,
        summary: summary || null
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ message: 'Inventory prediction stored', prediction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// INSERT expense anomaly — called by FastAPI AI server
// No auth required — internal AI service call
//
// Expected body from FastAPI backend_client.py:
// { business_id, expense_id, anomaly_level, z_score, deviation_percentage, reason, amount, category }
//
// NOTE: anomaly is linked to expense_id (not transaction_id)
// expense_anomalies table stores expense_id as the foreign key
// =============================================
async function insertAnomaly(req, res) {
  const {
    business_id,
    expense_id,
    anomaly_level,
    z_score,
    deviation_percentage,
    reason,
    amount,
    category
  } = req.body;

  if (!business_id) return res.status(400).json({ error: 'business_id is required' });

  const validLevels = ['low', 'medium', 'high', 'critical'];
  const resolvedLevel = (anomaly_level && validLevels.includes(anomaly_level))
    ? anomaly_level
    : 'low';

  try {
    const { data, error } = await supabaseAdmin
      .from('expense_anomalies')
      .insert({
        business_id,
        expense_id: expense_id || null,
        anomaly_level: resolvedLevel,
        z_score: z_score || null,
        deviation_percentage: deviation_percentage || null,
        reason: reason || null,
        amount: amount || null,
        category: category || null
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ message: 'Anomaly stored', anomaly: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// GET latest predictions — mobile app calls this
// Requires: Bearer token (authenticate middleware)
// =============================================
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

// =============================================
// GET anomalies for current business
// Requires: Bearer token (authenticate middleware)
// =============================================
async function getAnomalies(req, res) {
  const business_id = req.profile.business_id;
  const { limit = 20, offset = 0 } = req.query;

  try {
    const { data, error, count } = await supabaseAdmin
      .from('expense_anomalies')
      .select('*, expenses(*)', { count: 'exact' })
      .eq('business_id', business_id)
      .order('created_at', { ascending: false })
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

    if (error) return res.status(400).json({ error: error.message });

    return res.status(200).json({ anomalies: data || [], total: count || 0 });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  insertCashflowPrediction,
  insertInventoryPrediction,
  insertAnomaly,
  getLatestPredictions,
  getAnomalies
}; */