const { supabaseAdmin } = require('../config/supabase');
const { auditLog } = require('../utils/auditLogger');
const { triggerCashflowAnalysis } = require('../utils/aiClient');

async function applyExpenseToMatchingBudget({
  businessId,
  category,
  amount,
  txDate
}) {
  if (!category || !category.trim() || !Number.isFinite(amount) || amount <= 0) {
    return;
  }

  const dateOnly = new Date(txDate || new Date()).toISOString().slice(0, 10);
  const normalizedCategory = category.trim().toLowerCase();

  const { data: budgets, error } = await supabaseAdmin
    .from('budgets')
    .select('budget_id, spent_amount, category, period_start, period_end')
    .eq('business_id', businessId)
    .eq('is_active', true);

  if (error || !budgets || budgets.length === 0) return;

  const match = budgets.find((b) => {
    const budgetCategory = (b.category || '').toString().trim().toLowerCase();
    if (!budgetCategory || budgetCategory !== normalizedCategory) return false;
    if (!b.period_start || !b.period_end) return true;
    return dateOnly >= b.period_start && dateOnly <= b.period_end;
  });

  if (!match) return;

  const nextSpent = Number.parseFloat(match.spent_amount || 0) + amount;
  await supabaseAdmin
    .from('budgets')
    .update({ spent_amount: nextSpent })
    .eq('budget_id', match.budget_id);
}

// =============================================
// INSERT transaction — triggers AI cashflow analysis
// =============================================
async function insertTransaction(req, res) {
  const { type, amount, description, category, date, transaction_date } = req.body;
  const business_id = req.profile.business_id;
  const parsedAmount = parseFloat(amount);
  const txDate = (date || transaction_date) ? new Date(date || transaction_date).toISOString() : new Date().toISOString();

  try {
    if (!['income', 'expense'].includes(type)) {
      return res.status(400).json({ error: 'type must be income or expense' });
    }
    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: 'amount must be greater than 0' });
    }

    const { data, error } = await supabaseAdmin
      .from('transactions')
      .insert({
        business_id,
        type,
        amount: parsedAmount,
        description: description || null,
        category: category || null,
        date: txDate
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });

    // Update business current_balance
    const balanceChange = type === 'income' ? parsedAmount : -parsedAmount;

    const { data: biz } = await supabaseAdmin
      .from('businesses')
      .select('current_balance')
      .eq('business_id', business_id)
      .single();

    if (biz) {
      await supabaseAdmin
        .from('businesses')
        .update({ current_balance: parseFloat(biz.current_balance) + balanceChange })
        .eq('business_id', business_id);
    }

    if (type === 'expense') {
      await applyExpenseToMatchingBudget({
        businessId: business_id,
        category,
        amount: parsedAmount,
        txDate
      });
    }

    await auditLog({
      userId: req.user.id,
      businessId: business_id,
      action: 'transaction.created',
      entityType: 'transaction',
      entityId: data.transaction_id,
      newValue: { type, amount, category },
      req
    });

    // Trigger AI cashflow analysis non-blocking — response returns immediately
    // AI runs in background after response is sent
    setImmediate(() => triggerCashflowAnalysis(supabaseAdmin, business_id));

    return res.status(201).json({ message: 'Transaction logged', transaction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// SELECT transactions
// =============================================
async function selectTransactions(req, res) {
  const business_id = req.profile.business_id;
  const { type, category, from_date, to_date, limit = 50, offset = 0 } = req.query;

  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('*', { count: 'exact' })
      .eq('business_id', business_id)
      .order('date', { ascending: false })
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

    if (type) query = query.eq('type', type);
    if (category) query = query.eq('category', category);
    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });

    return res.status(200).json({ transactions: data, total: count });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// CASHFLOW REPORT
// =============================================
async function getCashflowReport(req, res) {
  const business_id = req.profile.business_id;
  const { from_date, to_date } = req.query;

  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('type, amount, category, date')
      .eq('business_id', business_id);

    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error } = await query;
    if (error) return res.status(400).json({ error: error.message });

    const totals = data.reduce((acc, t) => {
      const amt = parseFloat(t.amount);
      if (t.type === 'income') acc.total_income += amt;
      else if (t.type === 'expense') acc.total_expenses += amt;
      return acc;
    }, { total_income: 0, total_expenses: 0 });

    totals.net_balance = totals.total_income - totals.total_expenses;
    totals.transaction_count = data.length;

    const by_category = data.reduce((acc, t) => {
      const cat = t.category || 'uncategorized';
      if (!acc[cat]) acc[cat] = { income: 0, expense: 0 };
      if (t.type === 'income') acc[cat].income += parseFloat(t.amount);
      if (t.type === 'expense') acc[cat].expense += parseFloat(t.amount);
      return acc;
    }, {});

    return res.status(200).json({
      report: { period: { from_date, to_date }, ...totals, by_category }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { insertTransaction, selectTransactions, getCashflowReport };





/*const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

async function insertTransaction(req, res) {
  const {
    type, amount, description,
    category, transaction_date
  } = req.body;

  if (!type || amount === undefined) {
    return res.status(400).json({ error: 'type and amount are required' });
  }

  const validTypes = ['income', 'expense', 'refund', 'adjustment'];
  if (!validTypes.includes(type)) {
    return res.status(400).json({ error: 'Invalid type', valid_options: validTypes });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('transactions')
      .insert({
        business_id: req.profile.business_id,
        date: transaction_date ? new Date(transaction_date).toISOString() : new Date().toISOString(),
        type,
        amount: parseFloat(amount),
        category: category || null,
        description: description || null
      })
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });

    await logActivity({
      userId: req.user.id,
      action: 'transaction.insert',
      entityType: 'transaction',
      entityId: data.transaction_id || data.id || null,
      details: { type, amount, category },
      req
    });

    return res.status(201).json({ message: 'Transaction logged', transaction: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function selectTransactions(req, res) {
  const {
    type, category,
    from_date, to_date,
    limit = 50, offset = 0
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('*', { count: 'exact' })
      .eq('business_id', req.profile.business_id)
      .order('date', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (type) query = query.eq('type', type);
    if (category) query = query.eq('category', category);
    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({
      transactions: data,
      total: count,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10)
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getCashflowReport(req, res) {
  const { from_date, to_date } = req.query;
  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('type, amount, category, date')
      .eq('business_id', req.profile.business_id);

    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error } = await query;
    if (error) return res.status(400).json({ error: error.message });

    const totals = data.reduce((acc, t) => {
      const amt = parseFloat(t.amount);
      if (t.type === 'income') acc.total_income += amt;
      else if (t.type === 'expense') acc.total_expenses += amt;
      else if (t.type === 'refund') acc.total_refunds += amt;
      return acc;
    }, { total_income: 0, total_expenses: 0, total_refunds: 0 });

    totals.net_balance = totals.total_income - totals.total_expenses + totals.total_refunds;
    totals.transaction_count = data.length;

    const by_category = data.reduce((acc, t) => {
      const cat = t.category || 'uncategorized';
      if (!acc[cat]) acc[cat] = { income: 0, expense: 0 };
      if (t.type === 'income') acc[cat].income += parseFloat(t.amount);
      if (t.type === 'expense') acc[cat].expense += parseFloat(t.amount);
      return acc;
    }, {});

    return res.status(200).json({
      report: {
        period: { from_date: from_date || null, to_date: to_date || null },
        ...totals,
        by_category
      }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { insertTransaction, selectTransactions, getCashflowReport };
*/
