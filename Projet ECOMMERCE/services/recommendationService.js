const { createClient } = require('@supabase/supabase-js');

class RecommendationService {
    constructor() {
        this.supabase = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_SERVICE_ROLE_KEY
        );
    }

    /**
     * Ajoute une consultation de produit à l'historique
     * @param {string} userId - ID de l'utilisateur
     * @param {number} productId - ID du produit consulté
     * @returns {Promise<Object>}
     */
    async addProductView(userId, productId) {
        try {
            const { data, error } = await this.supabase
                .rpc('add_product_view', {
                    user_id_param: userId,
                    product_id_param: productId
                });

            if (error) {
                console.error('Erreur lors de l\'ajout de la consultation:', error);
                throw error;
            }

            return { success: true, message: 'Consultation enregistrée' };
        } catch (error) {
            console.error('Erreur dans addProductView:', error);
            throw error;
        }
    }

    /**
     * Met à jour la durée de consultation d'un produit
     * @param {string} userId - ID de l'utilisateur
     * @param {number} productId - ID du produit
     * @param {number} durationSeconds - Durée en secondes
     * @returns {Promise<Object>}
     */
    async updateViewDuration(userId, productId, durationSeconds) {
        try {
            const { data, error } = await this.supabase
                .rpc('update_view_duration', {
                    user_id_param: userId,
                    product_id_param: productId,
                    duration_seconds: durationSeconds
                });

            if (error) {
                console.error('Erreur lors de la mise à jour de la durée:', error);
                throw error;
            }

            return { success: true, message: 'Durée mise à jour' };
        } catch (error) {
            console.error('Erreur dans updateViewDuration:', error);
            throw error;
        }
    }

    /**
     * Récupère les recommandations pour un utilisateur
     * @param {string} userId - ID de l'utilisateur
     * @param {number} limit - Nombre de recommandations à retourner
     * @returns {Promise<Array>}
     */
    async getRecommendations(userId, limit = 10) {
        try {
            const { data, error } = await this.supabase
                .rpc('get_recommendations', {
                    user_id_param: userId,
                    limit_count: limit
                });

            if (error) {
                console.error('Erreur lors de la récupération des recommandations:', error);
                throw error;
            }

            return data || [];
        } catch (error) {
            console.error('Erreur dans getRecommendations:', error);
            throw error;
        }
    }

    /**
     * Récupère les préférences de catégories d'un utilisateur
     * @param {string} userId - ID de l'utilisateur
     * @returns {Promise<Array>}
     */
    async getUserCategoryPreferences(userId) {
        try {
            const { data, error } = await this.supabase
                .rpc('get_user_category_preferences', {
                    user_id_param: userId
                });

            if (error) {
                console.error('Erreur lors de la récupération des préférences:', error);
                throw error;
            }

            return data || [];
        } catch (error) {
            console.error('Erreur dans getUserCategoryPreferences:', error);
            throw error;
        }
    }

    /**
     * Récupère les statistiques détaillées d'un utilisateur
     * @param {string} userId - ID de l'utilisateur
     * @returns {Promise<Object>}
     */
    async getUserAnalytics(userId) {
        try {
            const { data, error } = await this.supabase
                .rpc('get_user_analytics', {
                    user_id_param: userId
                });

            if (error) {
                console.error('Erreur lors de la récupération des analytics:', error);
                throw error;
            }

            return data?.[0] || null;
        } catch (error) {
            console.error('Erreur dans getUserAnalytics:', error);
            throw error;
        }
    }

    /**
     * Récupère l'historique de consultation d'un utilisateur
     * @param {string} userId - ID de l'utilisateur
     * @param {number} limit - Nombre d'éléments à retourner
     * @returns {Promise<Array>}
     */
    async getUserHistory(userId, limit = 20) {
        try {
            const { data, error } = await this.supabase
                .from('history')
                .select(`
                    *,
                    products (
                        id,
                        nom,
                        prix_base,
                        description,
                        categorie,
                        marque,
                        images
                    )
                `)
                .eq('user_id', userId)
                .order('viewed_at', { ascending: false })
                .limit(limit);

            if (error) {
                console.error('Erreur lors de la récupération de l\'historique:', error);
                throw error;
            }

            return data || [];
        } catch (error) {
            console.error('Erreur dans getUserHistory:', error);
            throw error;
        }
    }

    /**
     * Récupère les statistiques de consultation pour un produit
     * @param {number} productId - ID du produit
     * @returns {Promise<Object>}
     */
    async getProductStats(productId) {
        try {
            const { data, error } = await this.supabase
                .from('history')
                .select('*')
                .eq('product_id', productId);

            if (error) {
                console.error('Erreur lors de la récupération des stats:', error);
                throw error;
            }

            const totalViews = data.length;
            const uniqueUsers = new Set(data.map(item => item.user_id)).size;
            const totalDuration = data.reduce((sum, item) => sum + (item.view_duration || 0), 0);
            const avgDuration = totalViews > 0 ? totalDuration / totalViews : 0;
            const recentViews = data.filter(item => {
                const viewDate = new Date(item.viewed_at);
                const thirtyDaysAgo = new Date();
                thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
                return viewDate >= thirtyDaysAgo;
            }).length;

            return {
                totalViews,
                uniqueUsers,
                totalDuration,
                avgDuration,
                recentViews
            };
        } catch (error) {
            console.error('Erreur dans getProductStats:', error);
            throw error;
        }
    }

    /**
     * Récupère les produits les plus populaires
     * @param {number} limit - Nombre de produits à retourner
     * @returns {Promise<Array>}
     */
    async getPopularProducts(limit = 10) {
        try {
            const { data, error } = await this.supabase
                .from('history')
                .select(`
                    product_id,
                    view_duration,
                    products (
                        id,
                        nom,
                        prix_base,
                        description,
                        categorie,
                        marque,
                        images
                    )
                `)
                .not('product_id', 'is', null);

            if (error) {
                console.error('Erreur lors de la récupération des produits populaires:', error);
                throw error;
            }

            // Compter les vues et durées par produit
            const productStats = {};
            data.forEach(item => {
                if (item.product_id && item.products) {
                    if (!productStats[item.product_id]) {
                        productStats[item.product_id] = {
                            product: item.products,
                            viewCount: 0,
                            totalDuration: 0
                        };
                    }
                    productStats[item.product_id].viewCount++;
                    productStats[item.product_id].totalDuration += (item.view_duration || 0);
                }
            });

            // Trier par score combiné (vues + durée) et retourner les plus populaires
            const popularProducts = Object.values(productStats)
                .map(item => ({
                    ...item.product,
                    viewCount: item.viewCount,
                    totalDuration: item.totalDuration,
                    popularityScore: item.viewCount * 0.4 + item.totalDuration * 0.6
                }))
                .sort((a, b) => b.popularityScore - a.popularityScore)
                .slice(0, limit);

            return popularProducts;
        } catch (error) {
            console.error('Erreur dans getPopularProducts:', error);
            throw error;
        }
    }

    /**
     * Nettoie l'historique ancien (plus de 90 jours)
     * @returns {Promise<Object>}
     */
    async cleanupOldHistory() {
        try {
            const ninetyDaysAgo = new Date();
            ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

            const { data, error } = await this.supabase
                .from('history')
                .delete()
                .lt('viewed_at', ninetyDaysAgo.toISOString());

            if (error) {
                console.error('Erreur lors du nettoyage:', error);
                throw error;
            }

            return { success: true, message: 'Historique ancien nettoyé' };
        } catch (error) {
            console.error('Erreur dans cleanupOldHistory:', error);
            throw error;
        }
    }
}

module.exports = RecommendationService; 