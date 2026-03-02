const { supabaseAdmin } = require('../config/supabase');

/**
 * Logs all significant actions to the audit_logs table.
 * Non-blocking — never crashes the request if logging fails.
 *
 * @param {Object} params
 * @param {string} params.userId      - UUID of user performing the action
 * @param {string} params.businessId  - UUID of the business
 * @param {string} params.action      - e.g. 'expense.approved', 'budget.created'
 * @param {string} params.entityType  - e.g. 'expense', 'budget', 'inventory'
 * @param {string} params.entityId    - UUID of the affected entity
 * @param {Object} params.oldValue    - State before change (for updates)
 * @param {Object} params.newValue    - State after change
 * @param {Object} params.req         - Express request object (for IP/user-agent)
 */
async function auditLog({
  userId,
  businessId,
  action,
  entityType,
  entityId,
  oldValue,
  newValue,
  req
}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({
      user_id: userId || null,
      business_id: businessId || null,
      action,
      entity_type: entityType || null,
      entity_id: entityId || null,
      old_value: oldValue || null,
      new_value: newValue || null,
      ip_address: req?.ip || null,
      user_agent: req?.headers?.['user-agent'] || null
    });
  } catch (err) {
    console.error('[AuditLog] Failed to write audit log:', err.message);
  }
}

module.exports = { auditLog };