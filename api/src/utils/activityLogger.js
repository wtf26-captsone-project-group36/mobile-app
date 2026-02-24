const { supabaseAdmin } = require('../config/supabase');

async function logActivity({ userId, action, entityType, entityId, details, req }) {
  try {
    await supabaseAdmin.from('activity_log').insert({
      user_id: userId,
      action,
      entity_type: entityType || null,
      entity_id: entityId || null,
      details: details || null,
      ip_address: req?.ip || null,
      user_agent: req?.headers?.['user-agent'] || null
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[ActivityLog] Failed to log activity:', err.message);
  }
}

module.exports = { logActivity };
