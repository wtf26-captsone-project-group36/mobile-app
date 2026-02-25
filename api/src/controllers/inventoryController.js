const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

/**
 * Inventory Controller
 * Handles CRUD operations for inventory with comprehensive validation
 */

async function insertItem(req, res) {
  const {
    name, sku, category, quantity, unit,
    purchase_price, reorder_level,
    expiry_date, location
  } = req.body;

  // ===== INPUT VALIDATION =====
  const validationErrors = validateInventoryInput({
    name,
    quantity,
    purchase_price,
    reorder_level,
    expiry_date
  });

  if (validationErrors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: validationErrors
    });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('inventory')
      .insert({
        business_id: req.profile.business_id,
        item_name: name.trim(),
        sku: sku ? sku.trim() : null,
        category: category ? category.trim() : null,
        quantity: parseFloat(quantity),
        unit: unit || 'units',
        expiry_date: expiry_date || null,
        purchase_price: purchase_price ? parseFloat(purchase_price) : null,
        reorder_level: reorder_level ? parseFloat(reorder_level) : null,
        location: location ? location.trim() : null,
        is_active: true
      })
      .select()
      .single();

    if (error) {
      console.error('[insertItem] Database error:', error);
      return res.status(400).json({
        error: 'Database error',
        message: error.message
      });
    }

    // Log the activity
    await logActivity({
      userId: req.user.id,
      action: 'inventory.insert',
      entityType: 'inventory',
      entityId: data.item_id || data.id || null,
      details: {
        name: name.trim(),
        quantity: parseFloat(quantity),
        sku: sku || null,
        category: category || null
      },
      req
    });

    // Auto-create alert if quantity <= reorder level
    if (parseFloat(quantity) <= (parseFloat(reorder_level) || 10)) {
      await createAutoAlert(
        req.user.id,
        data.item_id || data.id,
        'low_stock',
        `New item "${name}" added with quantity (${quantity}) at or below reorder level (${reorder_level || 10})`
      );
    }

    return res.status(201).json({
      message: 'Inventory item created',
      item: data
    });
  } catch (err) {
    console.error('[insertItem] Unexpected error:', err);
    return res.status(500).json({
      error: 'Internal server error',
      message: err.message
    });
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

  // ===== FETCH EXISTING ITEM WITH LOCK =====
  try {
    const { data: existing } = await supabaseAdmin
      .from('inventory')
      .select('*')
      .eq('item_id', id)
      .eq('business_id', req.profile.business_id)
      .single();

    if (!existing) {
      return res.status(404).json({
        error: 'Inventory item not found'
      });
    }

    // ===== VALIDATE UPDATES =====
    const validationErrors = validateInventoryUpdates(updates, existing);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        error: 'Validation failed',
        details: validationErrors
      });
    }

    // ===== PREPARE UPDATES =====
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
      if (allowedFields.includes(dbKey)) {
        const value = updates[key];
        // Trim strings
        if (typeof value === 'string') {
          cleanUpdates[dbKey] = value.trim();
        } else {
          cleanUpdates[dbKey] = value;
        }
      }
    });

    if (!Object.keys(cleanUpdates).length) {
      return res.status(400).json({
        error: 'No valid fields to update'
      });
    }

    // ===== EXECUTE UPDATE =====
    const { data, error } = await supabaseAdmin
      .from('inventory')
      .update(cleanUpdates)
      .eq('item_id', id)
      .eq('business_id', req.profile.business_id)
      .select()
      .single();

    if (error || !data) {
      console.error('[updateItem] Update error:', error);
      return res.status(404).json({
        error: 'Inventory item not found or update failed'
      });
    }

    // ===== LOG ACTIVITY =====
    await logActivity({
      userId: req.user.id,
      action: 'inventory.update',
      entityType: 'inventory',
      entityId: id,
      details: {
        before: existing,
        after: cleanUpdates,
        changes: Object.keys(cleanUpdates)
      },
      req
    });

    // ===== CHECK REORDER LEVEL AND CREATE ALERT =====
    const newQty = cleanUpdates.quantity ?? existing.quantity;
    const reorderLvl = cleanUpdates.reorder_level ?? existing.reorder_level;

    if (reorderLvl !== null && reorderLvl !== undefined && parseFloat(newQty) <= parseFloat(reorderLvl)) {
      await createAutoAlert(
        req.user.id,
        id,
        'low_stock',
        `"${data.item_name}" stock is low (${newQty} ${data.unit} remaining). Reorder level: ${reorderLvl}`
      );
    }

    return res.status(200).json({
      message: 'Inventory item updated',
      item: data
    });

  } catch (err) {
    console.error('[updateItem] Unexpected error:', err);
    return res.status(500).json({
      error: 'Internal server error',
      message: err.message
    });
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
    console.error('[createAutoAlert] Error creating alert:', err.message);
    // Don't fail the main operation if alert creation fails
  }
}

/**
 * Validate inventory input on create/update
 * @returns {Array} Array of error messages
 */
function validateInventoryInput(input, isUpdate = false) {
  const errors = [];

  // Name validation
  if (!isUpdate && (!input.name || typeof input.name !== 'string' || !input.name.trim())) {
    errors.push('Item name is required and must be a non-empty string');
  }
  if (isUpdate && input.name && (typeof input.name !== 'string' || !input.name.trim())) {
    errors.push('Item name must be a non-empty string');
  }

  // Quantity validation
  if (!isUpdate && (input.quantity === undefined || input.quantity === null)) {
    errors.push('Quantity is required');
  } else if (input.quantity !== undefined && input.quantity !== null) {
    const qty = parseFloat(input.quantity);
    if (isNaN(qty)) {
      errors.push('Quantity must be a valid number');
    } else if (qty < 0) {
      errors.push('Quantity cannot be negative');
    }
  }

  // Purchase price validation
  if (input.purchase_price !== undefined && input.purchase_price !== null) {
    const price = parseFloat(input.purchase_price);
    if (isNaN(price)) {
      errors.push('Purchase price must be a valid number');
    } else if (price < 0) {
      errors.push('Purchase price cannot be negative');
    }
  }

  // Reorder level validation
  if (input.reorder_level !== undefined && input.reorder_level !== null) {
    const level = parseFloat(input.reorder_level);
    if (isNaN(level)) {
      errors.push('Reorder level must be a valid number');
    } else if (level < 0) {
      errors.push('Reorder level cannot be negative');
    }
  }

  // Expiry date validation
  if (input.expiry_date !== undefined && input.expiry_date !== null) {
    const date = new Date(input.expiry_date);
    if (isNaN(date.getTime())) {
      errors.push('Expiry date must be a valid ISO 8601 date');
    }
  }

  return errors;
}

/**
 * Validate inventory updates
 * @returns {Array} Array of error messages
 */
function validateInventoryUpdates(updates, existing) {
  const errors = validateInventoryInput(updates, true);

  // Check if quantity decreased (potential sale - not allowed via update endpoint)
  if (updates.quantity !== undefined && parseFloat(updates.quantity) < parseFloat(existing.quantity)) {
    errors.push('Use the dedicated sales endpoint to decrease inventory');
  }

  return errors;
}

module.exports = { insertItem, selectItems, updateItem, deleteItem };
}