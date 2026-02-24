const { supabaseAdmin } = require('../config/supabase');
const { logActivity } = require('../utils/activityLogger');

/**
 * Sales Controller
 * Handles atomic inventory sales with transactional integrity
 * Ensures inventory decrements and cashflow increments happen together
 */

/**
 * Sell Inventory Item (Atomic Transaction)
 * @endpoint POST /sales/sell-item
 * @description Atomically decrements inventory and creates income transaction
 * Prevents "ghost stock" by using PostgreSQL RPC
 */
async function sellInventoryItem(req, res) {
  const {
    inventory_id,
    quantity_sold,
    selling_price,
    transaction_category,
    transaction_description
  } = req.body;

  // ===== INPUT VALIDATION =====
  const validationErrors = validateSaleInput({
    inventory_id,
    quantity_sold,
    selling_price,
    transaction_category
  });

  if (validationErrors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: validationErrors
    });
  }

  try {
    // Call atomic RPC function (executes both inventory update and transaction creation)
    const { data, error } = await supabaseAdmin.rpc('sell_inventory_item', {
      p_business_id: req.profile.business_id,
      p_inventory_id: inventory_id,
      p_quantity_sold: parseFloat(quantity_sold),
      p_selling_price: parseFloat(selling_price),
      p_transaction_category: transaction_category || 'Sales',
      p_transaction_description: transaction_description || null
    });

    // Handle RPC-level errors
    if (error) {
      console.error('[SellInventoryItem] RPC Error:', error);
      return res.status(500).json({
        error: 'Failed to process sale',
        message: error.message
      });
    }

    // Handle business logic errors returned in RPC response
    if (!data || data.length === 0) {
      return res.status(500).json({
        error: 'No response from database',
        message: 'Unexpected database error'
      });
    }

    const result = data[0];

    if (!result.success) {
      // Log failed sale attempt for audit trail
      await logActivity({
        userId: req.user.id,
        action: 'sale.failed',
        entityType: 'sale',
        entityId: null,
        details: {
          inventory_id,
          quantity_attempted: quantity_sold,
          error_code: result.error_code,
          error_message: result.message
        },
        req
      });

      // Return appropriate HTTP status based on error code
      const statusCodeMap = {
        'ITEM_NOT_FOUND': 404,
        'INSUFFICIENT_STOCK': 409,
        'INVALID_QUANTITY': 400,
        'INVALID_PRICE': 400,
        'DATABASE_ERROR': 500
      };

      return res.status(statusCodeMap[result.error_code] || 500).json({
        error: 'Sale processing failed',
        code: result.error_code,
        message: result.message,
        details: {
          remaining_quantity: result.remaining_quantity
        }
      });
    }

    // ===== SUCCESS: Log the successful transaction =====
    await logActivity({
      userId: req.user.id,
      action: 'sale.completed',
      entityType: 'sale',
      entityId: result.transaction_id,
      details: {
        inventory_id: result.inventory_item_id,
        quantity_sold,
        selling_price,
        total_amount: selling_price * quantity_sold,
        remaining_quantity: result.remaining_quantity,
        transaction_id: result.transaction_id
      },
      req
    });

    // Check if inventory falls below reorder level and create alert if needed
    await checkAndCreateReorderAlert(
      req.user.id,
      result.inventory_item_id,
      result.remaining_quantity,
      req.profile.business_id
    );

    return res.status(200).json({
      message: 'Sale completed successfully',
      data: {
        success: true,
        inventory_id: result.inventory_item_id,
        quantity_sold: parseFloat(quantity_sold),
        remaining_quantity: result.remaining_quantity,
        transaction_id: result.transaction_id,
        transaction_amount: selling_price * quantity_sold,
        timestamp: new Date().toISOString()
      }
    });

  } catch (err) {
    console.error('[sellInventoryItem] Unexpected Error:', err);
    return res.status(500).json({
      error: 'Internal server error during sale processing',
      message: err.message
    });
  }
}

/**
 * Purchase Inventory Item (Atomic Transaction)
 * @endpoint POST /sales/purchase-item
 * @description Atomically increments inventory and creates expense transaction
 */
async function purchaseInventoryItem(req, res) {
  const {
    inventory_id,
    quantity_purchased,
    cost_price,
    transaction_category,
    transaction_description
  } = req.body;

  // ===== INPUT VALIDATION =====
  const validationErrors = validatePurchaseInput({
    inventory_id,
    quantity_purchased,
    cost_price,
    transaction_category
  });

  if (validationErrors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: validationErrors
    });
  }

  try {
    // Call atomic RPC function
    const { data, error } = await supabaseAdmin.rpc('purchase_inventory_item', {
      p_business_id: req.profile.business_id,
      p_inventory_id: inventory_id,
      p_quantity_purchased: parseFloat(quantity_purchased),
      p_cost_price: parseFloat(cost_price),
      p_transaction_category: transaction_category || 'Purchases',
      p_transaction_description: transaction_description || null
    });

    if (error) {
      console.error('[PurchaseInventoryItem] RPC Error:', error);
      return res.status(500).json({
        error: 'Failed to process purchase',
        message: error.message
      });
    }

    if (!data || data.length === 0) {
      return res.status(500).json({
        error: 'No response from database',
        message: 'Unexpected database error'
      });
    }

    const result = data[0];

    if (!result.success) {
      await logActivity({
        userId: req.user.id,
        action: 'purchase.failed',
        entityType: 'purchase',
        entityId: null,
        details: {
          inventory_id,
          quantity_attempted: quantity_purchased,
          error_code: result.error_code,
          error_message: result.message
        },
        req
      });

      const statusCodeMap = {
        'ITEM_NOT_FOUND': 404,
        'INVALID_QUANTITY': 400,
        'INVALID_PRICE': 400,
        'DATABASE_ERROR': 500
      };

      return res.status(statusCodeMap[result.error_code] || 500).json({
        error: 'Purchase processing failed',
        code: result.error_code,
        message: result.message
      });
    }

    // ===== SUCCESS: Log the transaction =====
    await logActivity({
      userId: req.user.id,
      action: 'purchase.completed',
      entityType: 'purchase',
      entityId: result.transaction_id,
      details: {
        inventory_id: result.inventory_item_id,
        quantity_purchased,
        cost_price,
        total_amount: cost_price * quantity_purchased,
        new_quantity: result.new_quantity,
        transaction_id: result.transaction_id
      },
      req
    });

    return res.status(200).json({
      message: 'Purchase recorded successfully',
      data: {
        success: true,
        inventory_id: result.inventory_item_id,
        quantity_purchased: parseFloat(quantity_purchased),
        new_quantity: result.new_quantity,
        transaction_id: result.transaction_id,
        transaction_amount: cost_price * quantity_purchased,
        timestamp: new Date().toISOString()
      }
    });

  } catch (err) {
    console.error('[purchaseInventoryItem] Unexpected Error:', err);
    return res.status(500).json({
      error: 'Internal server error during purchase processing',
      message: err.message
    });
  }
}

/**
 * Get Sale History
 * @endpoint GET /sales/history
 * @description Returns all sales (income transactions) for the business
 */
async function getSaleHistory(req, res) {
  const {
    limit = 50,
    offset = 0,
    from_date,
    to_date,
    category
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('*', { count: 'exact' })
      .eq('business_id', req.profile.business_id)
      .eq('type', 'income')
      .order('date', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);
    if (category) query = query.eq('category', category);

    const { data, error, count } = await query;

    if (error) {
      return res.status(400).json({
        error: 'Failed to fetch sale history',
        message: error.message
      });
    }

    return res.status(200).json({
      sales: data,
      total: count,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10)
    });

  } catch (err) {
    return res.status(500).json({
      error: err.message
    });
  }
}

/**
 * Get Purchase History
 * @endpoint GET /sales/purchases
 * @description Returns all purchases (expense transactions) for the business
 */
async function getPurchaseHistory(req, res) {
  const {
    limit = 50,
    offset = 0,
    from_date,
    to_date
  } = req.query;

  try {
    let query = supabaseAdmin
      .from('transactions')
      .select('*', { count: 'exact' })
      .eq('business_id', req.profile.business_id)
      .eq('type', 'expense')
      .order('date', { ascending: false })
      .range(parseInt(offset, 10), parseInt(offset, 10) + parseInt(limit, 10) - 1);

    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error, count } = await query;

    if (error) {
      return res.status(400).json({
        error: 'Failed to fetch purchase history',
        message: error.message
      });
    }

    return res.status(200).json({
      purchases: data,
      total: count,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10)
    });

  } catch (err) {
    return res.status(500).json({
      error: err.message
    });
  }
}

// ===== HELPER FUNCTIONS =====

/**
 * Validate sale input
 * @returns {Array} Array of validation error messages
 */
function validateSaleInput(input) {
  const errors = [];

  // Validate inventory_id
  if (!input.inventory_id || typeof input.inventory_id !== 'string') {
    errors.push('inventory_id is required and must be a UUID string');
  }

  // Validate quantity_sold
  if (input.quantity_sold === undefined || input.quantity_sold === null) {
    errors.push('quantity_sold is required');
  } else {
    const qty = parseFloat(input.quantity_sold);
    if (isNaN(qty)) {
      errors.push('quantity_sold must be a valid number');
    } else if (qty <= 0) {
      errors.push('quantity_sold must be greater than 0');
    }
  }

  // Validate selling_price
  if (input.selling_price === undefined || input.selling_price === null) {
    errors.push('selling_price is required');
  } else {
    const price = parseFloat(input.selling_price);
    if (isNaN(price)) {
      errors.push('selling_price must be a valid number');
    } else if (price < 0) {
      errors.push('selling_price cannot be negative');
    }
  }

  // Validate transaction_category (optional but if provided, must be string)
  if (input.transaction_category !== undefined && typeof input.transaction_category !== 'string') {
    errors.push('transaction_category must be a string');
  }

  return errors;
}

/**
 * Validate purchase input
 * @returns {Array} Array of validation error messages
 */
function validatePurchaseInput(input) {
  const errors = [];

  if (!input.inventory_id || typeof input.inventory_id !== 'string') {
    errors.push('inventory_id is required and must be a UUID string');
  }

  if (input.quantity_purchased === undefined || input.quantity_purchased === null) {
    errors.push('quantity_purchased is required');
  } else {
    const qty = parseFloat(input.quantity_purchased);
    if (isNaN(qty)) {
      errors.push('quantity_purchased must be a valid number');
    } else if (qty <= 0) {
      errors.push('quantity_purchased must be greater than 0');
    }
  }

  if (input.cost_price === undefined || input.cost_price === null) {
    errors.push('cost_price is required');
  } else {
    const price = parseFloat(input.cost_price);
    if (isNaN(price)) {
      errors.push('cost_price must be a valid number');
    } else if (price < 0) {
      errors.push('cost_price cannot be negative');
    }
  }

  if (input.transaction_category !== undefined && typeof input.transaction_category !== 'string') {
    errors.push('transaction_category must be a string');
  }

  return errors;
}

/**
 * Check inventory level and create alert if below reorder level
 */
async function checkAndCreateReorderAlert(userId, inventoryId, currentQuantity, businessId) {
  try {
    // Fetch inventory details including reorder level
    const { data: item } = await supabaseAdmin
      .from('inventory')
      .select('item_name, reorder_level')
      .eq('item_id', inventoryId)
      .eq('business_id', businessId)
      .single();

    if (!item) return;

    // Create alert if below reorder level
    if (item.reorder_level && currentQuantity <= item.reorder_level) {
      await supabaseAdmin.from('risk_alerts').insert({
        user_id: userId,
        inventory_id: inventoryId,
        alert_type: 'low_stock',
        message: `"${item.item_name}" stock is low (${currentQuantity} remaining). Reorder level: ${item.reorder_level}`,
        severity: currentQuantity === 0 ? 'critical' : 'high'
      });
    }
  } catch (err) {
    console.error('[checkAndCreateReorderAlert] Error:', err.message);
    // Don't fail the sale if alert creation fails
  }
}

module.exports = {
  sellInventoryItem,
  purchaseInventoryItem,
  getSaleHistory,
  getPurchaseHistory
};
