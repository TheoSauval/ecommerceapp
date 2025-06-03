const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const auth = require('../middleware/auth');

// Toutes les routes nécessitent une authentification
router.use(auth);

// GET /api/cart
router.get('/', cartController.getCart);

// POST /api/cart
router.post('/', cartController.addToCart);

// PUT /api/cart/:itemId
router.put('/:itemId', cartController.updateCartItem);

// DELETE /api/cart/:itemId
router.delete('/:itemId', cartController.removeFromCart);

module.exports = router; 