const express = require('express');
const router = express.Router();
const RecommendationService = require('../services/recommendationService');
const { authenticateToken } = require('../middleware/auth');

const recommendationService = new RecommendationService();

/**
 * @route POST /api/recommendations/view
 * @desc Enregistrer une consultation de produit
 * @access Private
 */
router.post('/view', authenticateToken, async (req, res) => {
    try {
        const { productId } = req.body;
        const userId = req.user.id;

        if (!productId) {
            return res.status(400).json({ 
                success: false, 
                message: 'ID du produit requis' 
            });
        }

        const result = await recommendationService.addProductView(userId, productId);
        
        res.json({
            success: true,
            message: 'Consultation enregistrée avec succès',
            data: result
        });
    } catch (error) {
        console.error('Erreur lors de l\'enregistrement de la consultation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'enregistrement de la consultation',
            error: error.message
        });
    }
});

/**
 * @route PUT /api/recommendations/duration
 * @desc Mettre à jour la durée de consultation d'un produit
 * @access Private
 */
router.put('/duration', authenticateToken, async (req, res) => {
    try {
        const { productId, durationSeconds } = req.body;
        const userId = req.user.id;

        if (!productId || durationSeconds === undefined) {
            return res.status(400).json({ 
                success: false, 
                message: 'ID du produit et durée requis' 
            });
        }

        const result = await recommendationService.updateViewDuration(userId, productId, durationSeconds);
        
        res.json({
            success: true,
            message: 'Durée mise à jour avec succès',
            data: result
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la durée:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la durée',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations
 * @desc Récupérer les recommandations pour l'utilisateur connecté
 * @access Private
 */
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const limit = parseInt(req.query.limit) || 10;

        const recommendations = await recommendationService.getRecommendations(userId, limit);
        
        res.json({
            success: true,
            data: recommendations,
            count: recommendations.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des recommandations:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des recommandations',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations/categories
 * @desc Récupérer les préférences de catégories de l'utilisateur
 * @access Private
 */
router.get('/categories', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;

        const preferences = await recommendationService.getUserCategoryPreferences(userId);
        
        res.json({
            success: true,
            data: preferences,
            count: preferences.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des préférences:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des préférences',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations/analytics
 * @desc Récupérer les statistiques détaillées de l'utilisateur
 * @access Private
 */
router.get('/analytics', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;

        const analytics = await recommendationService.getUserAnalytics(userId);
        
        res.json({
            success: true,
            data: analytics
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des analytics:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des analytics',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations/history
 * @desc Récupérer l'historique de consultation de l'utilisateur
 * @access Private
 */
router.get('/history', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const limit = parseInt(req.query.limit) || 20;

        const history = await recommendationService.getUserHistory(userId, limit);
        
        res.json({
            success: true,
            data: history,
            count: history.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'historique:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de l\'historique',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations/popular
 * @desc Récupérer les produits les plus populaires
 * @access Public
 */
router.get('/popular', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 10;

        const popularProducts = await recommendationService.getPopularProducts(limit);
        
        res.json({
            success: true,
            data: popularProducts,
            count: popularProducts.length
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des produits populaires:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des produits populaires',
            error: error.message
        });
    }
});

/**
 * @route GET /api/recommendations/stats/:productId
 * @desc Récupérer les statistiques de consultation d'un produit
 * @access Public
 */
router.get('/stats/:productId', async (req, res) => {
    try {
        const productId = parseInt(req.params.productId);

        if (!productId) {
            return res.status(400).json({
                success: false,
                message: 'ID du produit requis'
            });
        }

        const stats = await recommendationService.getProductStats(productId);
        
        res.json({
            success: true,
            data: stats
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques',
            error: error.message
        });
    }
});

/**
 * @route DELETE /api/recommendations/history
 * @desc Supprimer l'historique de consultation de l'utilisateur
 * @access Private
 */
router.delete('/history', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;

        // Supprimer tout l'historique de l'utilisateur
        const { error } = await recommendationService.supabase
            .from('history')
            .delete()
            .eq('user_id', userId);

        if (error) {
            throw error;
        }

        res.json({
            success: true,
            message: 'Historique supprimé avec succès'
        });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'historique:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression de l\'historique',
            error: error.message
        });
    }
});

/**
 * @route POST /api/recommendations/cleanup
 * @desc Nettoyer l'historique ancien (admin seulement)
 * @access Private (Admin)
 */
router.post('/cleanup', authenticateToken, async (req, res) => {
    try {
        // Vérifier si l'utilisateur est admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès refusé. Rôle admin requis.'
            });
        }

        const result = await recommendationService.cleanupOldHistory();
        
        res.json({
            success: true,
            message: 'Nettoyage effectué avec succès',
            data: result
        });
    } catch (error) {
        console.error('Erreur lors du nettoyage:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du nettoyage',
            error: error.message
        });
    }
});

module.exports = router; 