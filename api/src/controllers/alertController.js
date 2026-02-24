const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

async function insertAlert(req, res) {
  const {
    user_id,
    inventory_id,
    alert_type,
    message,
    severity = 'medium',
    metadata
  } = req.body;

  const validTypes = ['expiry_warning', 'low_stock', 'overstock', 'surplus_available'];
  const validSeverities = ['low', 'medium', 'high', 'critical'];

  if (!user_id || !alert_type || !message) {
    return res.status(400).json({ error: 'user_id, alert_type, and message are required' });
  }
  if (!validTypes.includes(alert_type)) {
    return res.status(400).json({ error: 'Invalid alert_type', valid_options: validTypes });
  }
  if (!validSeverities.includes(severity)) {
    return res.status(400).json({ error: 'Invalid severity', valid_options: validSeverities });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('risk_alerts')
      .insert({
        user_id,
        inventory_id: inventory_id || null,
        alert_type,
        message,
        severity,
        metadata: metadata || null
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ message: 'Alert created', alert: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getAlerts(req, res) {
  const {
    alert_type, severity, is_read,
    limit = 20, offset = 0
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('risk_alerts')
      .select('*, inventory:inventory_id(item_name, quantity, unit)', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (alert_type) query = query.eq('alert_type', alert_type);
    if (severity) query = query.eq('severity', severity);
    if (is_read !== undefined) query = query.eq('is_read', is_read === 'true');

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ alerts: data, total: count, unread: data.filter((a) => !a.is_read).length });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function markAlertRead(req, res) {
  const { id } = req.params;
  try {
    const { data, error } = await supabaseAdmin
      .from('risk_alerts')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error || !data) return res.status(404).json({ error: 'Alert not found' });
    return res.status(200).json({ message: 'Alert marked as read', alert: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function resolveAlert(req, res) {
  const { id } = req.params;
  try {
    const { data, error } = await supabaseAdmin
      .from('risk_alerts')
      .update({ is_resolved: true, is_read: true })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();
    if (error || !data) return res.status(404).json({ error: 'Alert not found' });

    await logActivity({
      userId: req.user.id,
      action: 'alert.resolved',
      entityType: 'risk_alert',
      entityId: id,
      req
    });

    return res.status(200).json({ message: 'Alert resolved', alert: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { insertAlert, getAlerts, markAlertRead, resolveAlert };
