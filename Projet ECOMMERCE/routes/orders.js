const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const auth = require('../middleware/auth');

// Toutes les routes nécessitent une authentification
router.use(auth);

// GET /api/orders
router.get('/', orderController.getOrders);

// POST /api/orders
router.post('/', orderController.createOrder);

// GET /api/orders/:id
router.get('/:id', orderController.getOrderById);

// PUT /api/orders/:id/cancel
router.put('/:id/cancel', orderController.cancelOrder);

module.exports = router; 