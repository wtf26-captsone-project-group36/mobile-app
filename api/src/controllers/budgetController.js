const { supabaseAdmin } = require('../config/supabase');
const { auditLog } = require('../utils/auditLogger');

// =============================================
// CREATE BUDGET — owner or manager only
// =============================================
async function createBudget(req, res) {
  const {
    name, category, total_amount, allocated_amount, amount,
    period_start, period_end, start_date, end_date,
    alert_threshold = 80
  } = req.body;

  const business_id = req.profile.business_id;
  const resolvedAmount = parseFloat(total_amount ?? allocated_amount ?? amount);
  const resolvedName = (name || category || 'Budget').toString();
  const now = new Date();
  const defaultStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
  const defaultEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().slice(0, 10);
  const resolvedStart = period_start || start_date || defaultStart;
  const resolvedEnd = period_end || end_date || defaultEnd;

  try {
    if (Number.isNaN(resolvedAmount) || resolvedAmount <= 0) {
      return res.status(400).json({ error: 'total_amount must be greater than 0' });
    }

    const { data, error } = await supabaseAdmin
      .from('budgets')
      .insert({
        business_id,
        name: resolvedName,
        category: category || null,
        total_amount: resolvedAmount,
        period_start: resolvedStart,
        period_end: resolvedEnd,
        alert_threshold: parseFloat(alert_threshold),
        created_by: req.user.id
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });

    await auditLog({
      userId: req.user.id,
      businessId: business_id,
      action: 'budget.created',
      entityType: 'budget',
      entityId: data.budget_id,
      newValue: data,
      req
    });

    return res.status(201).json({
      message: 'Budget created',
      budget: {
        ...data,
        allocated_amount: data.total_amount,
      }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// GET ALL BUDGETS for current business
// =============================================
async function getBudgets(req, res) {
  const business_id = req.profile.business_id;
  const { is_active, category } = req.query;

  try {
    let query = supabaseAdmin
      .from('budgets')
      .select('*')
      .eq('business_id', business_id)
      .order('created_at', { ascending: false });

    if (is_active !== undefined) query = query.eq('is_active', is_active === 'true');
    if (category) query = query.eq('category', category);

    const { data, error } = await query;
    if (error) return res.status(400).json({ error: error.message });

    // Add percentage spent to each budget
    const enriched = data.map((b) => ({
      ...b,
      allocated_amount: b.total_amount,
      percent_spent: b.total_amount > 0
        ? parseFloat(((b.spent_amount / b.total_amount) * 100).toFixed(2))
        : 0,
      is_over_threshold: b.total_amount > 0
        ? (b.spent_amount / b.total_amount) * 100 >= b.alert_threshold
        : false
    }));

    return res.status(200).json({ budgets: enriched });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// GET SINGLE BUDGET
// =============================================
async function getBudgetById(req, res) {
  const { id } = req.params;
  const business_id = req.profile.business_id;

  try {
    let { data, error } = await supabaseAdmin
      .from('budgets')
      .select('*, expenses(*)')
      .eq('budget_id', id)
      .eq('business_id', business_id)
      .single();

    if (error) {
      ({ data, error } = await supabaseAdmin
        .from('budgets')
        .select('*')
        .eq('budget_id', id)
        .eq('business_id', business_id)
        .single());
    }

    if (error || !data) return res.status(404).json({ error: 'Budget not found' });

    return res.status(200).json({
      budget: {
        ...data,
        allocated_amount: data.total_amount,
      }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// UPDATE BUDGET
// =============================================
async function updateBudget(req, res) {
  const { id } = req.params;
  const business_id = req.profile.business_id;
  const {
    name,
    category,
    total_amount,
    allocated_amount,
    amount,
    period_start,
    period_end,
    start_date,
    end_date,
    alert_threshold,
    is_active
  } = req.body;

  try {
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('budgets')
      .select('*')
      .eq('budget_id', id)
      .eq('business_id', business_id)
      .single();

    if (fetchError || !existing) return res.status(404).json({ error: 'Budget not found' });

    const updates = {};
    if (name) updates.name = name;
    if (category !== undefined) updates.category = category;
    const resolvedAmount = total_amount ?? allocated_amount ?? amount;
    if (resolvedAmount !== undefined) updates.total_amount = parseFloat(resolvedAmount);
    if (period_start || start_date) updates.period_start = period_start || start_date;
    if (period_end || end_date) updates.period_end = period_end || end_date;
    if (alert_threshold) updates.alert_threshold = parseFloat(alert_threshold);
    if (is_active !== undefined) updates.is_active = is_active;

    const { data, error } = await supabaseAdmin
      .from('budgets')
      .update(updates)
      .eq('budget_id', id)
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });

    await auditLog({
      userId: req.user.id,
      businessId: business_id,
      action: 'budget.updated',
      entityType: 'budget',
      entityId: id,
      oldValue: existing,
      newValue: data,
      req
    });

    return res.status(200).json({
      message: 'Budget updated',
      budget: {
        ...data,
        allocated_amount: data.total_amount,
      }
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// =============================================
// DELETE BUDGET (soft delete)
// =============================================
async function deleteBudget(req, res) {
  const { id } = req.params;
  const business_id = req.profile.business_id;

  try {
    const { data: existing } = await supabaseAdmin
      .from('budgets')
      .select('name')
      .eq('budget_id', id)
      .eq('business_id', business_id)
      .single();

    if (!existing) return res.status(404).json({ error: 'Budget not found' });

    const { error } = await supabaseAdmin
      .from('budgets')
      .update({ is_active: false })
      .eq('budget_id', id);

    if (error) return res.status(400).json({ error: error.message });

    await auditLog({
      userId: req.user.id,
      businessId: business_id,
      action: 'budget.deleted',
      entityType: 'budget',
      entityId: id,
      req
    });

    return res.status(200).json({ message: 'Budget deleted' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { createBudget, getBudgets, getBudgetById, updateBudget, deleteBudget };
