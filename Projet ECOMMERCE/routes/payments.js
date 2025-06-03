const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const auth = require('../middleware/auth');

// Toutes les routes nécessitent une authentification
router.use(auth);

// POST /api/payments
router.post('/', paymentController.initiatePayment);

// GET /api/payments/:orderId
router.get('/:orderId', paymentController.getPaymentStatus);

module.exports = router; 