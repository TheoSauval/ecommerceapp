const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const vendorAnalyticsController = require('../controllers/vendorAnalyticsController');

// Middleware d'authentification pour toutes les routes
router.use(authenticateToken);

// Routes pour les analyses vendeur

// GET /api/vendor-analytics/my-dashboard
// Dashboard du vendeur connecté
router.get('/my-dashboard', vendorAnalyticsController.getMyDashboard);

// GET /api/vendor-analytics/revenue/:vendorId
// Revenus d'un vendeur spécifique
router.get('/revenue/:vendorId', vendorAnalyticsController.getVendorRevenue);

// GET /api/vendor-analytics/top-products/:vendorId
// Top-produits d'un vendeur spécifique
router.get('/top-products/:vendorId', vendorAnalyticsController.getVendorTopProducts);

// GET /api/vendor-analytics/sales-stats/:vendorId
// Statistiques de vente d'un vendeur
router.get('/sales-stats/:vendorId', vendorAnalyticsController.getVendorSalesStats);

// GET /api/vendor-analytics/sales-history/:vendorId
// Historique des ventes d'un vendeur
router.get('/sales-history/:vendorId', vendorAnalyticsController.getVendorSalesHistory);

// GET /api/vendor-analytics/dashboard/:vendorId
// Dashboard complet d'un vendeur
router.get('/dashboard/:vendorId', vendorAnalyticsController.getVendorDashboard);

// GET /api/vendor-analytics/all-revenues
// Revenus de tous les vendeurs (pour admin)
router.get('/all-revenues', vendorAnalyticsController.getAllVendorRevenues);

// GET /api/vendor-analytics/global-stats
// Statistiques globales (pour admin)
router.get('/global-stats', vendorAnalyticsController.getGlobalStats);

module.exports = router; 