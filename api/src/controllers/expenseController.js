const { supabaseAdmin } = require('../config/supabase');
const { auditLog } = require('../utils/auditLogger');
const { triggerAnomalyDetection } = require('../utils/aiClient');

function toExpenseDto(row) {
  if (!row) return null;
  return {
    expense_id: row.expense_id || row.id,
    title: row.title || row.purpose || row.category || 'Expense',
    amount: Number.parseFloat(row.amount || 0),
    category: row.category || '',
    description: row.description || row.purpose || null,
    status: row.status || 'pending',
    submitted_at: row.created_at || new Date().toISOString(),
    created_at: row.created_at || new Date().toISOString(),
    receipt_url: row.receipt_url || null,
    submitted_by: row.requested_by || row.submitted_by || '',
    reviewed_by: row.reviewed_by || null,
    review_note: row.rejection_reason || row.review_note || null,
    reviewed_at: row.reviewed_at || null
  };
}

async function submitExpense(req, res) {
  const businessId = req.profile.business_id;
  const requestedBy = req.user.id;
  const {
    budget_id,
    category,
    amount,
    title,
    purpose,
    description,
    receipt_url
  } = req.body;

  const payload = {
    business_id: businessId,
    budget_id: budget_id || null,
    requested_by: requestedBy,
    category: category || 'General',
    amount: Number.parseFloat(amount || 0),
    purpose: purpose || title || description || 'Expense request',
    status: 'pending',
    receipt_url: receipt_url || null
  };

  try {
    const { data, error } = await supabaseAdmin
      .from('expenses')
      .insert(payload)
      .select('*')
      .single();

    if (error) return res.status(400).json({ error: error.message });

    await auditLog({
      userId: req.user.id,
      businessId,
      action: 'expense.submitted',
      entityType: 'expense',
      entityId: data.expense_id,
      newValue: payload,
      req
    });

    return res.status(201).json({
      message: 'Expense submitted',
      expense: toExpenseDto(data)
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getExpenses(req, res) {
  const businessId = req.profile.business_id;
  const role = req.profile.role;
  const userId = req.user.id;
  const { status, category, limit = 20, offset = 0 } = req.query;

  try {
    let query = supabaseAdmin
      .from('expenses')
      .select('*', { count: 'exact' })
      .eq('business_id', businessId)
      .order('created_at', { ascending: false })
      .range(Number.parseInt(offset, 10), Number.parseInt(offset, 10) + Number.parseInt(limit, 10) - 1);

    if (role === 'staff') {
      query = query.eq('requested_by', userId);
    }
    if (status) query = query.eq('status', status);
    if (category) query = query.eq('category', category);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });

    return res.status(200).json({
      expenses: (data || []).map(toExpenseDto),
      total: count || 0,
      limit: Number.parseInt(limit, 10),
      offset: Number.parseInt(offset, 10)
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getExpenseById(req, res) {
  const businessId = req.profile.business_id;
  const role = req.profile.role;
  const userId = req.user.id;
  const { id } = req.params;

  try {
    let query = supabaseAdmin
      .from('expenses')
      .select('*')
      .eq('business_id', businessId)
      .eq('expense_id', id);

    if (role === 'staff') {
      query = query.eq('requested_by', userId);
    }

    const { data, error } = await query.single();
    if (error || !data) return res.status(404).json({ error: 'Expense not found' });

    return res.status(200).json({ expense: toExpenseDto(data) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function reviewExpense(req, res) {
  const businessId = req.profile.business_id;
  const { id } = req.params;
  const decision = (req.body.decision || req.body.status || '').toLowerCase();
  const note = req.body.note || req.body.rejection_reason || null;

  const status = decision === 'approve' ? 'approved' : decision === 'reject' ? 'rejected' : decision;
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ error: 'decision/status must be approve/approved or reject/rejected' });
  }

  try {
    const { data: existing, error: existingError } = await supabaseAdmin
      .from('expenses')
      .select('*')
      .eq('business_id', businessId)
      .eq('expense_id', id)
      .single();

    if (existingError || !existing) return res.status(404).json({ error: 'Expense not found' });
    if (existing.status !== 'pending') return res.status(400).json({ error: 'Only pending expenses can be reviewed' });

    const updates = {
      status,
      reviewed_by: req.user.id,
      reviewed_at: new Date().toISOString(),
      rejection_reason: status === 'rejected' ? note : null
    };

    const { data, error } = await supabaseAdmin
      .from('expenses')
      .update(updates)
      .eq('expense_id', id)
      .select('*')
      .single();

    if (error) return res.status(400).json({ error: error.message });

    if (status === 'approved') {
      await supabaseAdmin
        .from('transactions')
        .insert({
          business_id: businessId,
          date: new Date().toISOString(),
          type: 'expense',
          amount: Number.parseFloat(existing.amount || 0),
          category: existing.category || null,
          description: existing.purpose || null
        });

      setImmediate(() => triggerAnomalyDetection(supabaseAdmin, businessId));
    }

    await auditLog({
      userId: req.user.id,
      businessId,
      action: `expense.${status}`,
      entityType: 'expense',
      entityId: id,
      oldValue: existing,
      newValue: updates,
      req
    });

    return res.status(200).json({ message: `Expense ${status}`, expense: toExpenseDto(data) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function cancelExpense(req, res) {
  const businessId = req.profile.business_id;
  const userId = req.user.id;
  const role = req.profile.role;
  const { id } = req.params;

  try {
    let query = supabaseAdmin
      .from('expenses')
      .select('*')
      .eq('business_id', businessId)
      .eq('expense_id', id);

    if (role === 'staff') {
      query = query.eq('requested_by', userId);
    }

    const { data: existing, error: existingError } = await query.single();
    if (existingError || !existing) return res.status(404).json({ error: 'Expense not found' });
    if (existing.status !== 'pending') return res.status(400).json({ error: 'Only pending expenses can be cancelled' });

    const { data, error } = await supabaseAdmin
      .from('expenses')
      .update({ status: 'cancelled', updated_at: new Date().toISOString() })
      .eq('expense_id', id)
      .select('*')
      .single();

    if (error) return res.status(400).json({ error: error.message });

    await auditLog({
      userId: req.user.id,
      businessId,
      action: 'expense.cancelled',
      entityType: 'expense',
      entityId: id,
      oldValue: existing,
      newValue: { status: 'cancelled' },
      req
    });

    return res.status(200).json({ message: 'Expense cancelled', expense: toExpenseDto(data) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getExpenseSummary(req, res) {
  const businessId = req.profile.business_id;
  const role = req.profile.role;
  const userId = req.user.id;
  const { from_date, to_date } = req.query;

  try {
    let query = supabaseAdmin
      .from('expenses')
      .select('amount, status, created_at')
      .eq('business_id', businessId);

    if (role === 'staff') {
      query = query.eq('requested_by', userId);
    }
    if (from_date) query = query.gte('created_at', from_date);
    if (to_date) query = query.lte('created_at', to_date);

    const { data, error } = await query;
    if (error) return res.status(400).json({ error: error.message });

    const summary = (data || []).reduce((acc, row) => {
      const amount = Number.parseFloat(row.amount || 0);
      acc.total_submitted += amount;
      if (row.status === 'approved') acc.total_approved += amount;
      if (row.status === 'pending') acc.total_pending += amount;
      if (row.status === 'rejected') acc.total_rejected += amount;
      if (row.status === 'cancelled') acc.total_cancelled += amount;
      acc.count += 1;
      return acc;
    }, {
      total_submitted: 0,
      total_approved: 0,
      total_pending: 0,
      total_rejected: 0,
      total_cancelled: 0,
      count: 0
    });

    return res.status(200).json({ summary });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  submitExpense,
  getExpenses,
  getExpenseById,
  reviewExpense,
  cancelExpense,
  getExpenseSummary
};
