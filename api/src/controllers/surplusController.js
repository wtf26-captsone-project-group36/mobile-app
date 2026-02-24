const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

async function createSurplus(req, res) {
  const {
    inventory_id, name, quantity, unit,
    description, expiry_date, pickup_deadline,
    is_free = true, price = 0, location
  } = req.body;

  if (!name || quantity === undefined) {
    return res.status(400).json({ error: 'name and quantity are required' });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('surplus')
      .insert({
        owner_id: req.user.id,
        inventory_id: inventory_id || null,
        name,
        quantity: parseFloat(quantity),
        unit: unit || 'units',
        description: description || null,
        expiry_date: expiry_date || null,
        pickup_deadline: pickup_deadline || null,
        is_free,
        price: parseFloat(price),
        location: location || null
      })
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });

    await logActivity({
      userId: req.user.id,
      action: 'surplus.create',
      entityType: 'surplus',
      entityId: data.id,
      details: { name, quantity },
      req
    });

    return res.status(201).json({ message: 'Surplus listed', surplus: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getAvailableSurplus(req, res) {
  const { limit = 20, offset = 0, location } = req.query;
  try {
    let query = supabaseAdmin
      .from('surplus')
      .select('*, owner:owner_id(full_name, business_type, business_name)', { count: 'exact' })
      .eq('status', 'available')
      .order('created_at', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);
    if (location) query = query.ilike('location', `%${location}%`);

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ surplus: data, total: count });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getMySurplus(req, res) {
  try {
    const { data, error } = await supabaseAdmin
      .from('surplus')
      .select('*')
      .eq('owner_id', req.user.id)
      .order('created_at', { ascending: false });
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ surplus: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function claimSurplus(req, res) {
  const { id } = req.params;
  try {
    const { data: existing } = await supabaseAdmin
      .from('surplus')
      .select('*')
      .eq('id', id)
      .eq('status', 'available')
      .single();
    if (!existing) return res.status(404).json({ error: 'Surplus not found or already claimed' });
    if (existing.owner_id === req.user.id) {
      return res.status(400).json({ error: 'Cannot claim your own surplus' });
    }

    const { data, error } = await supabaseAdmin
      .from('surplus')
      .update({ status: 'claimed', claimer_id: req.user.id })
      .eq('id', id)
      .select()
      .single();
    if (error) return res.status(400).json({ error: error.message });

    await logActivity({
      userId: req.user.id,
      action: 'surplus.claim',
      entityType: 'surplus',
      entityId: id,
      req
    });

    return res.status(200).json({ message: 'Surplus claimed', surplus: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function updateSurplusStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;
  const validStatuses = ['available', 'claimed', 'completed', 'expired'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status', valid_options: validStatuses });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('surplus')
      .update({ status })
      .eq('id', id)
      .eq('owner_id', req.user.id)
      .select()
      .single();
    if (error || !data) return res.status(404).json({ error: 'Surplus not found' });
    return res.status(200).json({ message: 'Surplus status updated', surplus: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { createSurplus, getAvailableSurplus, getMySurplus, claimSurplus, updateSurplusStatus };
