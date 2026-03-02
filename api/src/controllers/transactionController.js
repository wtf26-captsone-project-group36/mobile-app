const { supabaseAdmin } = require('../config/supabase');
const { auditLog } = require('../utils/auditLogger');
const { triggerCashflowAnalysis } = require('../utils/aiClient');

// =============================================
// INSERT transaction — triggers AI cashflow analysis
// =============================================
async function insertTransaction(req, res) {
  const { type, amount, description, category, date, transaction_date } = req.body;
  const business_id = req.profile.business_id;

  try {
    const { data, error } = await supabaseAdmin
      .from('transactions')
      .insert({
        business_id,
        type,
        amount: parseFloat(amount),
        description: description || null,
        category: category || null,
        date: (date || transaction_date) ? new Date(date || transaction_date).toISOString() : new Date().toISOString()
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });

    // Update business current_balance
    const balanceChange = type === 'income' ? parseFloat(amount) : -parseFloat(amount);

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
