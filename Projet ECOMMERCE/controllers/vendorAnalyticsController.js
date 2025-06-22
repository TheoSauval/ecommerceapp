const vendorAnalyticsService = require('../services/vendorAnalyticsService');
const { supabase } = require('../config/supabase');

class VendorAnalyticsController {
    
    /**
     * GET /api/vendor-analytics/revenue/:vendorId
     * Obtenir les revenus d'un vendeur
     */
    async getVendorRevenue(req, res) {
        try {
            const { vendorId } = req.params;
            
            if (!vendorId || isNaN(vendorId)) {
                return res.status(400).json({ 
                    error: 'ID vendeur invalide' 
                });
            }
            
            const revenue = await vendorAnalyticsService.getVendorRevenue(parseInt(vendorId));
            
            res.json({
                success: true,
                data: revenue
            });
        } catch (error) {
            console.error('Erreur dans getVendorRevenue:', error);
            res.status(500).json({ 
                error: 'Erreur lors du calcul des revenus',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/top-products/:vendorId
     * Obtenir les top-produits d'un vendeur
     */
    async getVendorTopProducts(req, res) {
        try {
            const { vendorId } = req.params;
            const { limit = 10 } = req.query;
            
            if (!vendorId || isNaN(vendorId)) {
                return res.status(400).json({ 
                    error: 'ID vendeur invalide' 
                });
            }
            
            const topProducts = await vendorAnalyticsService.getVendorTopProducts(
                parseInt(vendorId), 
                parseInt(limit)
            );
            
            res.json({
                success: true,
                data: topProducts
            });
        } catch (error) {
            console.error('Erreur dans getVendorTopProducts:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération des top-produits',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/sales-stats/:vendorId
     * Obtenir les statistiques de vente d'un vendeur
     */
    async getVendorSalesStats(req, res) {
        try {
            const { vendorId } = req.params;
            const { period = 30 } = req.query;
            
            if (!vendorId || isNaN(vendorId)) {
                return res.status(400).json({ 
                    error: 'ID vendeur invalide' 
                });
            }
            
            const salesStats = await vendorAnalyticsService.getVendorSalesStats(
                parseInt(vendorId), 
                parseInt(period)
            );
            
            res.json({
                success: true,
                data: salesStats
            });
        } catch (error) {
            console.error('Erreur dans getVendorSalesStats:', error);
            res.status(500).json({ 
                error: 'Erreur lors du calcul des statistiques',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/sales-history/:vendorId
     * Obtenir l'historique des ventes d'un vendeur
     */
    async getVendorSalesHistory(req, res) {
        try {
            const { vendorId } = req.params;
            const { days = 90 } = req.query;
            
            if (!vendorId || isNaN(vendorId)) {
                return res.status(400).json({ 
                    error: 'ID vendeur invalide' 
                });
            }
            
            const salesHistory = await vendorAnalyticsService.getVendorSalesHistory(
                parseInt(vendorId), 
                parseInt(days)
            );
            
            res.json({
                success: true,
                data: salesHistory
            });
        } catch (error) {
            console.error('Erreur dans getVendorSalesHistory:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération de l\'historique',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/dashboard/:vendorId
     * Obtenir le dashboard complet d'un vendeur
     */
    async getVendorDashboard(req, res) {
        try {
            const { vendorId } = req.params;
            
            if (!vendorId || isNaN(vendorId)) {
                return res.status(400).json({ 
                    error: 'ID vendeur invalide' 
                });
            }
            
            const dashboard = await vendorAnalyticsService.getVendorDashboard(parseInt(vendorId));
            
            res.json({
                success: true,
                data: dashboard
            });
        } catch (error) {
            console.error('Erreur dans getVendorDashboard:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération du dashboard',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/all-revenues
     * Obtenir les revenus de tous les vendeurs
     */
    async getAllVendorRevenues(req, res) {
        try {
            const revenues = await vendorAnalyticsService.getAllVendorRevenues();
            
            res.json({
                success: true,
                data: revenues
            });
        } catch (error) {
            console.error('Erreur dans getAllVendorRevenues:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération des revenus',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/global-stats
     * Obtenir les statistiques globales (admin)
     */
    async getGlobalStats(req, res) {
        try {
            const globalStats = await vendorAnalyticsService.getGlobalStats();
            
            res.json({
                success: true,
                data: globalStats
            });
        } catch (error) {
            console.error('Erreur dans getGlobalStats:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération des statistiques globales',
                details: error.message 
            });
        }
    }
    
    /**
     * GET /api/vendor-analytics/my-dashboard
     * Obtenir le dashboard du vendeur connecté
     */
    async getMyDashboard(req, res) {
        try {
            const userId = req.user.id;
            
            // Récupérer l'ID du vendeur à partir de l'utilisateur connecté
            const { data: vendor, error: vendorError } = await supabase
                .from('vendors')
                .select('id')
                .eq('user_id', userId)
                .single();
                
            if (vendorError || !vendor) {
                return res.status(404).json({ 
                    error: 'Vendeur non trouvé pour cet utilisateur' 
                });
            }
            
            const dashboard = await vendorAnalyticsService.getVendorDashboard(vendor.id);
            
            res.json({
                success: true,
                data: dashboard
            });
        } catch (error) {
            console.error('Erreur dans getMyDashboard:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération du dashboard',
                details: error.message 
            });
        }
    }
}

module.exports = new VendorAnalyticsController(); 