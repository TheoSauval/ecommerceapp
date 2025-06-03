const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const auth = require('../middleware/auth');

// GET /api/products - Liste paginée de tous les produits
router.get('/', productController.getAllProducts);

// GET /api/products/search - Recherche full-text
router.get('/search', productController.searchProducts);

// GET /api/products/:id - Détails d'un produit
router.get('/:id', productController.getProductById);

module.exports = router; 