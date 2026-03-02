const express = require('express');
const router = express.Router();

// Controllers
const authController = require('../controllers/authController');
const inventoryController = require('../controllers/inventoryController');
const transactionController = require('../controllers/transactionController');
const saleController = require('../controllers/saleController');
const alertController = require('../controllers/alertController');
const surplusController = require('../controllers/surplusController');
const activityController = require('../controllers/activityController');
const budgetController = require('../controllers/budgetController');
const expenseController = require('../controllers/expenseController');
const predictionController = require('../controllers/predictionController');
const auditController = require('../controllers/auditController');

// Middleware
const { authenticate, requireRole } = require('../middleware/auth');

// =============================================
// HEALTH CHECK (public)
// =============================================
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    name: 'HerVest API',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// =============================================
// AUTH ROUTES
// =============================================

// Public
router.post('/auth/signup', authController.signUp);
router.post('/auth/signup/verify', authController.verifySignup);
router.post('/auth/signin', authController.signIn);
router.post('/auth/refresh', authController.refreshToken);
router.post('/password/reset', authController.sendPasswordResetOTP);
router.post('/password/verify', authController.verifyOTPAndResetPassword);

// Protected
router.post('/auth/signout', authenticate, authController.signOut);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);
router.get('/auth/user/:id', authenticate, authController.getUserById);

// Owner only — delete user
router.delete(
  '/auth/user/:id',
  authenticate,
  requireRole('owner'),
  authController.deleteUser
);

// =============================================
// INVENTORY ROUTES
// =============================================

// Owner and manager — full CRUD
router.post(
  '/inventory',
  authenticate,
  requireRole('owner', 'manager'),
  inventoryController.insertItem
);

// All roles — view inventory
router.get('/inventory', authenticate, inventoryController.selectItems);

// Owner and manager — update and delete
router.put(
  '/inventory/:id',
  authenticate,
  requireRole('owner', 'manager'),
  inventoryController.updateItem
);

router.delete(
  '/inventory/:id',
  authenticate,
  requireRole('owner', 'manager'),
  inventoryController.deleteItem
);

// =============================================
// TRANSACTION / CASHFLOW ROUTES
// =============================================

// Owner and manager — log transactions
router.post(
  '/transactions',
  authenticate,
  requireRole('owner', 'manager'),
  transactionController.insertTransaction
);

// All roles — view transactions and reports
router.get('/transactions', authenticate, transactionController.selectTransactions);
router.get('/transactions/report', authenticate, transactionController.getCashflowReport);

// =============================================
// SALES ROUTES (ATOMIC INVENTORY + CASHFLOW)
// =============================================
router.post('/sales/sell-item', authenticate, saleController.sellInventoryItem);
router.post('/sales/purchase-item', authenticate, saleController.purchaseInventoryItem);
router.get('/sales/history', authenticate, saleController.getSaleHistory);
router.get('/sales/purchases', authenticate, saleController.getPurchaseHistory);

// =============================================
// BUDGET ROUTES
// =============================================

// Owner and manager — create and manage budgets
router.post(
  '/budgets',
  authenticate,
  requireRole('owner', 'manager'),
  budgetController.createBudget
);

// All roles — view budgets
router.get('/budgets', authenticate, budgetController.getBudgets);
router.get('/budgets/:id', authenticate, budgetController.getBudgetById);

// Owner and manager — update and delete
router.put(
  '/budgets/:id',
  authenticate,
  requireRole('owner', 'manager'),
  budgetController.updateBudget
);

router.delete(
  '/budgets/:id',
  authenticate,
  requireRole('owner'),
  budgetController.deleteBudget
);

// =============================================
// EXPENSE ROUTES
// =============================================

// All roles — submit expense requests
router.post(
  '/expenses',
  authenticate,
  expenseController.submitExpense
);

// All roles — view (staff see own, managers/owners see all)
router.get('/expenses', authenticate, expenseController.getExpenses);
router.get('/expenses/summary', authenticate, expenseController.getExpenseSummary);
router.get('/expenses/:id', authenticate, expenseController.getExpenseById);

// Owner and manager — approve or reject
router.put(
  '/expenses/:id/review',
  authenticate,
  requireRole('owner', 'manager'),
  expenseController.reviewExpense
);

// Requester only — cancel their own pending expense
router.put('/expenses/:id/cancel', authenticate, expenseController.cancelExpense);

// =============================================
// ALERT ROUTES
// =============================================
router.get('/alerts', authenticate, alertController.getAlerts);
router.put('/alerts/:id/read', authenticate, alertController.markAlertRead);
router.put('/alerts/:id/resolve', authenticate, alertController.resolveAlert);
router.post('/alerts', alertController.insertAlert);

// =============================================
// SURPLUS ROUTES
// =============================================
router.get('/surplus', surplusController.getAvailableSurplus);
router.post('/surplus', authenticate, surplusController.createSurplus);
router.get('/surplus/mine', authenticate, surplusController.getMySurplus);
router.put('/surplus/:id/claim', authenticate, surplusController.claimSurplus);
router.put('/surplus/:id/status', authenticate, surplusController.updateSurplusStatus);

// =============================================
// ACTIVITY ROUTES
// =============================================
router.get('/activity', authenticate, activityController.getUserActivity);
router.post('/activity', authenticate, activityController.insertActivity);

// =============================================
// PREDICTION ROUTES
// =============================================

// Protected — mobile app reads predictions
router.get('/predictions', authenticate, predictionController.getLatestPredictions);
router.get('/predictions/anomalies', authenticate, predictionController.getAnomalies);

// AI server endpoints — no user auth (called by FastAPI with service role)
// These are intentionally open but should be secured with an API key in production
router.post('/predictions/cashflow', predictionController.insertCashflowPrediction);
router.post('/predictions/inventory', predictionController.insertInventoryPrediction);
router.post('/predictions/anomalies', predictionController.insertAnomaly);

// =============================================
// AUDIT LOG ROUTES — owner only
// =============================================
router.get(
  '/audit-logs',
  authenticate,
  requireRole('owner'),
  auditController.getAuditLogs
);

module.exports = router;







/*const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const inventoryController = require('../controllers/inventoryController');
const transactionController = require('../controllers/transactionController');
const saleController = require('../controllers/saleController');
const alertController = require('../controllers/alertController');
const surplusController = require('../controllers/surplusController');
const activityController = require('../controllers/activityController');
const predictionController = require('../controllers/predictionController');

const { authenticate, requireRole } = require('../middleware/auth');

// AUTH ROUTES
router.post('/auth/signup', authController.signUp);
router.post('/auth/signup/verify', authController.verifySignup);
router.post('/auth/signin', authController.signIn);
router.post('/auth/refresh', authController.refreshToken);
router.post('/auth/password/reset', authController.sendPasswordResetOTP);
router.post('/auth/password/verify', authController.verifyOTPAndResetPassword);
router.post('/auth/signout', authenticate, authController.signOut);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);
router.delete('/auth/user/:id', authenticate, requireRole('owner'), authController.deleteUser);

// INVENTORY ROUTES
router.post('/inventory', authenticate, inventoryController.insertItem);
router.get('/inventory', authenticate, inventoryController.selectItems);
router.put('/inventory/:id', authenticate, inventoryController.updateItem);
router.delete('/inventory/:id', authenticate, inventoryController.deleteItem);

// TRANSACTION ROUTES
router.post('/transactions', authenticate, transactionController.insertTransaction);
router.get('/transactions', authenticate, transactionController.selectTransactions);
router.get('/transactions/report', authenticate, transactionController.getCashflowReport);

// SALES ROUTES (ATOMIC INVENTORY + CASHFLOW)
router.post('/sales/sell-item', authenticate, saleController.sellInventoryItem);
router.post('/sales/purchase-item', authenticate, saleController.purchaseInventoryItem);
router.get('/sales/history', authenticate, saleController.getSaleHistory);
router.get('/sales/purchases', authenticate, saleController.getPurchaseHistory);

// ALERT ROUTES
router.get('/alerts', authenticate, alertController.getAlerts);
router.put('/alerts/:id/read', authenticate, alertController.markAlertRead);
router.put('/alerts/:id/resolve', authenticate, alertController.resolveAlert);
router.post('/alerts', alertController.insertAlert);

// SURPLUS ROUTES
router.get('/surplus', surplusController.getAvailableSurplus);
router.post('/surplus', authenticate, surplusController.createSurplus);
router.get('/surplus/mine', authenticate, surplusController.getMySurplus);
router.put('/surplus/:id/claim', authenticate, surplusController.claimSurplus);
router.put('/surplus/:id/status', authenticate, surplusController.updateSurplusStatus);

// ACTIVITY ROUTES
router.get('/activity', authenticate, activityController.getUserActivity);
router.post('/activity', authenticate, activityController.insertActivity);

// PREDICTIONS
router.get('/predictions', authenticate, predictionController.getLatestPredictions);
router.get('/predictions/anomalies', authenticate, predictionController.getAnomalies);
router.post('/predictions/cashflow', predictionController.insertCashflowPrediction);
router.post('/predictions/inventory', predictionController.insertInventoryPrediction);
router.post('/predictions/anomalies', predictionController.insertAnomaly);

// HEALTH CHECK
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

module.exports = router;
*/
