const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const paymentController = require('../controllers/paymentController');

// Toutes les routes nécessitent une authentification sauf le webhook Stripe
router.use(authenticateToken);

// POST /api/payments
router.post('/', paymentController.createPayment);

// GET /api/payments
router.get('/', paymentController.getPayments);

// GET /api/payments/:id
router.get('/:id', paymentController.getPaymentById);

// PUT /api/payments/:id/status
router.put('/:id/status', paymentController.updatePaymentStatus);

// POST /api/payments/stripe/initiate
router.post('/stripe/initiate', paymentController.initiatePayment);

// GET /api/payments/stripe/:orderId/status
router.get('/stripe/:orderId/status', paymentController.getPaymentStatus);

// Route spéciale pour le webhook Stripe (pas d'authentification)
router.post('/webhook', paymentController.handleWebhook);

module.exports = router; 