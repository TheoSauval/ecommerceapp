const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const productController = require('../controllers/productController');

// Exemple : protéger les routes qui nécessitent une authentification
// router.use(authenticateToken);

// GET /api/products - Liste paginée de tous les produits
router.get('/', productController.getAllProducts);

// GET /api/products/search - Recherche full-text
router.get('/search', productController.searchProducts);

// GET /api/products/categories - Récupérer toutes les catégories disponibles
router.get('/categories', productController.getAvailableCategories);

// GET /api/products/category/:category - Produits filtrés par catégorie
router.get('/category/:category', productController.getProductsByCategory);

// GET /api/products/:id - Détails d'un produit
router.get('/:id', productController.getProductById);

// POST /api/products (protégé)
router.post('/', authenticateToken, productController.createProduct);

// PUT /api/products/:id (protégé)
router.put('/:id', authenticateToken, productController.updateProduct);

// DELETE /api/products/:id (protégé)
router.delete('/:id', authenticateToken, productController.deleteProduct);

module.exports = router; 