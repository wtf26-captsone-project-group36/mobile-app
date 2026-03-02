const http = require('http');

const AI_BASE_URL = process.env.AI_URL || 'http://hervest-ai:8000';

// =============================================
// CORE HTTP CALLER
// Non-blocking — never crashes the main request
// Logs full response body for debugging
// =============================================
async function callAI(path, payload) {
  try {
    const body = JSON.stringify(payload);
    const url = new URL(path, AI_BASE_URL);

    await new Promise((resolve, reject) => {
      const options = {
        hostname: url.hostname,
        port: url.port || 8000,
        path: url.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body)
        },
        timeout: 10000
      };

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          console.log(`[AI Client] POST ${path} → ${res.statusCode} ${data}`);
          resolve(data);
        });
      });

      req.on('error', (err) => {
        console.error(`[AI Client] POST ${path} failed:`, err.message);
        reject(err);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error(`AI request to ${path} timed out`));
      });

      req.write(body);
      req.end();
    });
  } catch (err) {
    console.error(`[AI Client] Non-blocking failure for ${path}:`, err.message);
  }
}

// =============================================
// CASHFLOW ANALYSIS
// Triggered after: POST /api/transactions
//
// FastAPI CashflowRequest expects:
// { "business_id": "uuid", "transactions": [...] }
//
// Each transaction requires:
// transaction_id, date, type, amount, category,
// description, current_balance
//
// FastAPI then POSTs to Node.js /api/predictions/cashflow
// which also requires business_id — passed through via business_id field
// =============================================
async function triggerCashflowAnalysis(supabaseAdmin, businessId) {
  try {
    const { data: business } = await supabaseAdmin
      .from('businesses')
      .select('current_balance')
      .eq('business_id', businessId)
      .single();

    const currentBalance = business ? parseFloat(business.current_balance) : 0;

    const { data: transactions } = await supabaseAdmin
      .from('transactions')
      .select('transaction_id, type, amount, category, date, description')
      .eq('business_id', businessId)
      .order('date', { ascending: false })
      .limit(100);

    if (!transactions || transactions.length === 0) {
      console.log('[AI Client] No transactions found for cashflow analysis');
      return;
    }

    const enriched = transactions.map(tx => ({
      transaction_id: tx.transaction_id,
      date: tx.date,
      type: tx.type,
      amount: parseFloat(tx.amount),
      category: tx.category || 'uncategorized',
      description: tx.description || '',
      current_balance: currentBalance
    }));

    // business_id is included so FastAPI can pass it through to Node.js
    await callAI('/run/cashflow', {
      business_id: businessId,
      transactions: enriched
    });
  } catch (err) {
    console.error('[AI Client] triggerCashflowAnalysis failed:', err.message);
  }
}

// =============================================
// INVENTORY EXPIRY ANALYSIS
// Triggered after: POST /api/inventory, PUT /api/inventory/:id
//
// FastAPI InventoryExpiryRequest expects:
// { "business_id": "uuid", "payload": { "inventory": [...], "current_date": "YYYY-MM-DD" } }
//
// Each item requires:
// item_id, item_name, quantity, unit, expiry_date
// Optional: purchase_price
//
// FastAPI then POSTs to Node.js /api/predictions/inventory
// which requires business_id — passed through via business_id field
// =============================================
async function triggerInventoryAnalysis(supabaseAdmin, businessId) {
  try {
    const { data: inventory } = await supabaseAdmin
      .from('inventory')
      .select('item_id, item_name, quantity, unit, expiry_date, purchase_price, category')
      .eq('business_id', businessId);

    if (!inventory || inventory.length === 0) {
      console.log('[AI Client] No inventory found for expiry analysis');
      return;
    }

    const today = new Date().toISOString().split('T')[0];

    await callAI('/run/inventory-expiry', {
      business_id: businessId,
      payload: {
        inventory: inventory.map(item => ({
          item_id: item.item_id,
          item_name: item.item_name,
          quantity: parseFloat(item.quantity),
          unit: item.unit,
          expiry_date: item.expiry_date,
          purchase_price: item.purchase_price ? parseFloat(item.purchase_price) : null,
          category: item.category || 'uncategorized'
        })),
        current_date: today
      }
    });
  } catch (err) {
    console.error('[AI Client] triggerInventoryAnalysis failed:', err.message);
  }
}

// =============================================
// EXPENSE ANOMALY DETECTION
// Triggered after: expense approved (staff or owner/manager)
//
// FastAPI AnomalyRequest expects:
// { "business_id": "uuid", "payload": { "expenses": [...] } }
//
// Each expense requires: amount
// Optional: expense_id, category, purpose, created_at
// Needs min 5 expenses for MAD z-score — below 5 uses fallback-max
//
// FastAPI then POSTs to Node.js /api/predictions/anomalies
// which requires business_id — passed through via business_id field
// =============================================
async function triggerAnomalyDetection(supabaseAdmin, businessId) {
  try {
    const { data: expenses } = await supabaseAdmin
      .from('expenses')
      .select('expense_id, amount, category, purpose, created_at, status')
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
      .limit(100);

    if (!expenses || expenses.length === 0) {
      console.log('[AI Client] No approved expenses found for anomaly detection');
      return;
    }
    
    if (expenses.length < 5) {
       console.log(`[AI Client] Only ${expenses.length} approved expenses — AI will use fallback-max method`);
    }
       console.log('[AI Client] Anomaly amounts:', JSON.stringify(expenses.map(e => e.amount)));
    
    await callAI('/run/anomalies', {
      business_id: businessId,
      payload: {
        expenses: expenses.map(e => ({
          expense_id: e.expense_id,
          amount: parseFloat(e.amount),
          category: e.category || 'uncategorized',
          purpose: e.purpose || '',
          created_at: e.created_at
        }))
      }
    });
  } catch (err) {
    console.error('[AI Client] triggerAnomalyDetection failed:', err.message);
  }
}

module.exports = {
  triggerCashflowAnalysis,
  triggerInventoryAnalysis,
  triggerAnomalyDetection
};