const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

async function insertItem(req, res) {
  const {
    name, sku, category, quantity, unit,
    purchase_price, reorder_level,
    expiry_date, location
  } = req.body;

  if (!name || quantity === undefined) {
    return res.status(400).json({ error: 'name and quantity are required' });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('inventory')
      .insert({
        business_id: req.profile.business_id,
        item_name: name,
        sku: sku || null,
        category: category || null,
        quantity: parseFloat(quantity),
        unit: unit || 'units',
        expiry_date: expiry_date || null,
        purchase_price: purchase_price ? parseFloat(purchase_price) : null,
        reorder_level: reorder_level ? parseFloat(reorder_level) : null,
        location: location || null,
        is_active: true
      })
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });

    await logActivity({
      userId: req.user.id,
      action: 'inventory.insert',
      entityType: 'inventory',
      entityId: data.item_id || data.id || null,
      details: { name, quantity, sku },
      req
    });

    if (parseFloat(quantity) <= (parseFloat(reorder_level) || 10)) {
      await createAutoAlert(req.user.id, data.item_id || data.id, 'low_stock',
        `New item "${name}" added with quantity (${quantity}) at or below reorder level`);
    }

    return res.status(201).json({ message: 'Inventory item created', item: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function selectItems(req, res) {
  const {
    category, low_stock, expiring_soon_days,
    search, limit = 50, offset = 0,
    order_by = 'created_at', order_dir = 'desc'
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('inventory')
      .select('*', { count: 'exact' })
      .eq('business_id', req.profile.business_id)
      .eq('is_active', true)
      .order(order_by, { ascending: order_dir === 'asc' })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (category) query = query.eq('category', category);
    if (low_stock === 'true') query = query.filter('quantity', 'lte', 'reorder_level');
    if (search) query = query.or(`item_name.ilike.%${search}%,sku.ilike.%${search}%,category.ilike.%${search}%`);

    if (expiring_soon_days) {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + parseInt(expiring_soon_days, 10));
      query = query
        .not('expiry_date', 'is', null)
        .lte('expiry_date', futureDate.toISOString().split('T')[0]);
    }

    const { data, error, count } = await query;
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ items: data, total: count, limit: parseInt(limit, 10), offset: parseInt(offset, 10) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function updateItem(req, res) {
  const { id } = req.params;
  const updates = req.body;

  const { data: existing } = await supabaseAdmin
    .from('inventory')
    .select('*')
    .eq('item_id', id)
    .eq('business_id', req.profile.business_id)
    .single();
  if (!existing) return res.status(404).json({ error: 'Inventory item not found' });

  const allowedFields = [
    'item_name', 'sku', 'category', 'quantity', 'unit',
    'purchase_price', 'reorder_level', 'expiry_date', 'location', 'is_active'
  ];

  const incomingToDb = {
    name: 'item_name',
    cost_price: 'purchase_price'
  };

  const cleanUpdates = {};
  Object.keys(updates).forEach((key) => {
    const dbKey = incomingToDb[key] || key;
    if (allowedFields.includes(dbKey)) cleanUpdates[dbKey] = updates[key];
  });
  if (!Object.keys(cleanUpdates).length) {
    return res.status(400).json({ error: 'No valid fields to update' });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('inventory')
      .update(cleanUpdates)
      .eq('item_id', id)
      .eq('business_id', req.profile.business_id)
      .select()
      .single();
    if (error || !data) return res.status(404).json({ error: 'Inventory item not found' });

    await logActivity({
      userId: req.user.id,
      action: 'inventory.update',
      entityType: 'inventory',
      entityId: id,
      details: { before: existing, after: cleanUpdates },
      req
    });

    const newQty = cleanUpdates.quantity ?? existing.quantity;
    const reorderLvl = cleanUpdates.reorder_level ?? existing.reorder_level;
    if (reorderLvl !== null && reorderLvl !== undefined && parseFloat(newQty) <= parseFloat(reorderLvl)) {
      await createAutoAlert(req.user.id, id, 'low_stock', `"${data.item_name}" stock is low (${newQty} ${data.unit} remaining)`);
    }

    return res.status(200).json({ message: 'Inventory item updated', item: data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function deleteItem(req, res) {
  const { id } = req.params;
  try {
    const { data: existing } = await supabaseAdmin
      .from('inventory')
      .select('item_name')
      .eq('item_id', id)
      .eq('business_id', req.profile.business_id)
      .single();
    if (!existing) return res.status(404).json({ error: 'Item not found' });

    const { error } = await supabaseAdmin
      .from('inventory')
      .update({ is_active: false })
      .eq('item_id', id)
      .eq('business_id', req.profile.business_id);
    if (error) return res.status(400).json({ error: error.message });

    await logActivity({
      userId: req.user.id,
      action: 'inventory.delete',
      entityType: 'inventory',
      entityId: id,
      details: { name: existing.item_name },
      req
    });

    return res.status(200).json({ message: 'Inventory item deleted' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function createAutoAlert(userId, inventoryId, alertType, message) {
  try {
    await supabaseAdmin.from('risk_alerts').insert({
      user_id: userId,
      inventory_id: inventoryId,
      alert_type: alertType,
      message,
      severity: alertType === 'low_stock' ? 'high' : 'medium'
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[AutoAlert] Failed:', err.message);
  }
}

module.exports = { insertItem, selectItems, updateItem, deleteItem };
