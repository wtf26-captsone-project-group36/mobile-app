const { supabaseAdmin } = require('../config/supabase');

function toAuditDto(row) {
  return {
    audit_log_id: row.audit_id || row.audit_log_id || row.id,
    user_id: row.user_id || '',
    action: row.action || '',
    resource: row.entity_type || row.resource || '',
    resource_id: row.entity_id || row.resource_id || '',
    changes: {
      old_value: row.old_value || null,
      new_value: row.new_value || null
    },
    timestamp: row.created_at || row.timestamp || new Date().toISOString(),
    ip_address: row.ip_address || null
  };
}

async function getAuditLogs(req, res) {
  const businessId = req.profile.business_id;
  const {
    action,
    entity_type,
    user_id,
    from_date,
    to_date,
    limit = 50,
    offset = 0
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('audit_logs')
      .select('*', { count: 'exact' })
      .eq('business_id', businessId)
      .order('created_at', { ascending: false })
      .range(Number.parseInt(offset, 10), Number.parseInt(offset, 10) + Number.parseInt(limit, 10) - 1);

    if (action) query = query.ilike('action', `%${action}%`);
    if (entity_type) query = query.eq('entity_type', entity_type);
    if (user_id) query = query.eq('user_id', user_id);
    if (from_date) query = query.gte('created_at', from_date);
    if (to_date) query = query.lte('created_at', to_date);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });

    return res.status(200).json({
      audit_logs: (data || []).map(toAuditDto),
      total: count || 0
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { getAuditLogs };
