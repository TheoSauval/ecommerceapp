const { supabase } = require('../config/supabase');

class VendorAnalyticsService {
    
    /**
     * Obtenir les revenus totaux d'un vendeur
     */
    async getVendorRevenue(vendorId) {
        try {
            const { data, error } = await supabase.rpc('get_vendor_revenue', {
                vendor_id_param: vendorId
            });
            
            if (error) {
                console.error('Erreur lors du calcul des revenus:', error);
                throw error;
            }
            
            return data[0] || {
                total_revenue: 0,
                total_orders: 0,
                total_products_sold: 0
            };
        } catch (error) {
            console.error('Erreur dans getVendorRevenue:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir les top-produits d'un vendeur
     */
    async getVendorTopProducts(vendorId, limit = 10) {
        try {
            const { data, error } = await supabase.rpc('get_vendor_top_products', {
                vendor_id_param: vendorId,
                limit_count: limit
            });
            
            if (error) {
                console.error('Erreur lors de la récupération des top-produits:', error);
                throw error;
            }
            
            return data || [];
        } catch (error) {
            console.error('Erreur dans getVendorTopProducts:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir les statistiques de vente d'un vendeur
     */
    async getVendorSalesStats(vendorId, periodDays = 30) {
        try {
            const { data, error } = await supabase.rpc('get_vendor_sales_stats', {
                vendor_id_param: vendorId,
                period_days: periodDays
            });
            
            if (error) {
                console.error('Erreur lors du calcul des statistiques:', error);
                throw error;
            }
            
            return data[0] || {
                period_revenue: 0,
                period_orders: 0,
                period_products_sold: 0,
                average_order_value: 0,
                best_selling_product: 'Aucun',
                best_selling_product_quantity: 0
            };
        } catch (error) {
            console.error('Erreur dans getVendorSalesStats:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir l'historique des ventes d'un vendeur
     */
    async getVendorSalesHistory(vendorId, daysBack = 90) {
        try {
            const { data, error } = await supabase.rpc('get_vendor_sales_history', {
                vendor_id_param: vendorId,
                days_back: daysBack
            });
            
            if (error) {
                console.error('Erreur lors de la récupération de l\'historique:', error);
                throw error;
            }
            
            return data || [];
        } catch (error) {
            console.error('Erreur dans getVendorSalesHistory:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir les revenus de tous les vendeurs (via la vue)
     */
    async getAllVendorRevenues() {
        try {
            const { data, error } = await supabase
                .from('vendor_revenues')
                .select('*')
                .order('total_revenue', { ascending: false });
            
            if (error) {
                console.error('Erreur lors de la récupération des revenus:', error);
                throw error;
            }
            
            return data || [];
        } catch (error) {
            console.error('Erreur dans getAllVendorRevenues:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir un résumé complet pour un vendeur
     */
    async getVendorDashboard(vendorId) {
        try {
            const [
                revenue,
                topProducts,
                salesStats,
                salesHistory
            ] = await Promise.all([
                this.getVendorRevenue(vendorId),
                this.getVendorTopProducts(vendorId, 5),
                this.getVendorSalesStats(vendorId, 30),
                this.getVendorSalesHistory(vendorId, 30)
            ]);
            
            return {
                revenue,
                topProducts,
                salesStats,
                salesHistory,
                lastUpdated: new Date().toISOString()
            };
        } catch (error) {
            console.error('Erreur dans getVendorDashboard:', error);
            throw error;
        }
    }
    
    /**
     * Obtenir les statistiques globales pour l'admin
     */
    async getGlobalStats() {
        try {
            // Revenus totaux
            const { data: totalRevenue, error: revenueError } = await supabase
                .from('payments')
                .select('amount')
                .eq('status', 'Payé');
                
            if (revenueError) throw revenueError;
            
            // Commandes totales
            const { data: totalOrders, error: ordersError } = await supabase
                .from('orders')
                .select('id')
                .eq('status', 'Payé');
                
            if (ordersError) throw ordersError;
            
            // Produits vendus
            const { data: totalProducts, error: productsError } = await supabase
                .from('order_variants')
                .select('quantity')
                .in('order_id', totalOrders.map(o => o.id));
                
            if (productsError) throw productsError;
            
            // Vendeurs actifs
            const { data: activeVendors, error: vendorsError } = await supabase
                .from('vendors')
                .select('id');
                
            if (vendorsError) throw vendorsError;
            
            return {
                totalRevenue: totalRevenue.reduce((sum, p) => sum + parseFloat(p.amount), 0),
                totalOrders: totalOrders.length,
                totalProductsSold: totalProducts.reduce((sum, p) => sum + p.quantity, 0),
                activeVendors: activeVendors.length,
                averageOrderValue: totalOrders.length > 0 ? 
                    totalRevenue.reduce((sum, p) => sum + parseFloat(p.amount), 0) / totalOrders.length : 0
            };
        } catch (error) {
            console.error('Erreur dans getGlobalStats:', error);
            throw error;
        }
    }
}

module.exports = new VendorAnalyticsService(); 