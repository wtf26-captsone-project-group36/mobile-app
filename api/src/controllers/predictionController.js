const { supabaseAdmin } = require('../config/supabase');

async function insertCashflowPrediction(req, res) {
  const { business_id, risk_level, days_until_broke, confidence_score } = req.body;
  const { data, error } = await supabaseAdmin
    .from('cashflow_predictions')
    .insert({ business_id, risk_level, days_until_broke, confidence_score })
    .select()
    .single();
  if (error) return res.status(400).json({ error: error.message });
  return res.status(201).json({ prediction: data });
}

async function insertInventoryPrediction(req, res) {
  const { business_id, critical_items, warning_items, total_value_at_risk } = req.body;
  const { data, error } = await supabaseAdmin
    .from('inventory_predictions')
    .insert({ business_id, critical_items, warning_items, total_value_at_risk })
    .select()
    .single();
  if (error) return res.status(400).json({ error: error.message });
  return res.status(201).json({ prediction: data });
}

async function getLatestPredictions(req, res) {
  const business_id = req.profile.business_id;
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
}

async function insertAnomaly(req, res) {
  const { transaction_id, anomaly_level, z_score, deviation_percentage } = req.body;
  const { data, error } = await supabaseAdmin
    .from('expense_anomalies')
    .insert({ transaction_id, anomaly_level, z_score, deviation_percentage })
    .select()
    .single();
  if (error) return res.status(400).json({ error: error.message });
  return res.status(201).json({ anomaly: data });
}

async function getAnomalies(req, res) {
  const { data, error } = await supabaseAdmin
    .from('expense_anomalies')
    .select('*, transactions!inner(*)')
    .eq('transactions.business_id', req.profile.business_id)
    .order('created_at', { ascending: false });
  if (error) return res.status(400).json({ error: error.message });
  return res.status(200).json({ anomalies: data });
}

module.exports = {
  insertCashflowPrediction,
  insertInventoryPrediction,
  getLatestPredictions,
  insertAnomaly,
  getAnomalies
};
