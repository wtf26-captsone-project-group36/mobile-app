const { supabaseAdmin } = require('../config/supabase');

async function getUserActivity(req, res) {
  const {
    action, entity_type,
    from_date, to_date,
    limit = 50, offset = 0
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('activity_log')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (action) query = query.ilike('action', `%${action}%`);
    if (entity_type) query = query.eq('entity_type', entity_type);
    if (from_date) query = query.gte('created_at', from_date);
    if (to_date) query = query.lte('created_at', to_date);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ activities: data, total: count });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function insertActivity(req, res) {
  const { action, entity_type, entity_id, details } = req.body;
  if (!action) return res.status(400).json({ error: 'action is required' });

  try {
    const { data, error } = await supabaseAdmin
      .from('activity_log')
      .insert({
        user_id: req.user.id,
        action,
        entity_type: entity_type || null,
        entity_id: entity_id || null,
        details: details || null,
        ip_address: req.ip,
        user_agent: req.headers['user-agent']
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json({ activity: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { getUserActivity, insertActivity };
