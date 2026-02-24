const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const inventoryController = require('../controllers/inventoryController');
const transactionController = require('../controllers/transactionController');
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
