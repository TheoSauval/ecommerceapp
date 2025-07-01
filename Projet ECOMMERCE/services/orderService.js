const { supabase } = require('../config/supabase');

class OrderService {
    // Récupérer toutes les commandes d'un utilisateur
    async getOrders(userId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    order_id,
                    variant_id,
                    quantity,
                    unit_price,
                    product_variants (
                        *,
                        products (*),
                        colors (*),
                        heights (*)
                    )
                )
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        // Transformer les données pour correspondre au modèle Swift
        return data.map(order => ({
            ...order,
            order_variants: order.order_variants?.map(variant => ({
                ...variant,
                product_variant: variant.product_variants,
                product_variants: undefined
            }))
        }));
    }
    
    // Récupérer une commande par ID
    async getOrderById(orderId, userId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    order_id,
                    variant_id,
                    quantity,
                    unit_price,
                    product_variants (
                        *,
                        products (*),
                        colors (*),
                        heights (*)
                    )
                )
            `)
            .eq('id', orderId)
            .eq('user_id', userId)
            .single();
            
        if (error) throw error;
        
        // Transformer les données pour correspondre au modèle Swift
        return {
            ...data,
            order_variants: data.order_variants?.map(variant => ({
                ...variant,
                product_variant: variant.product_variants,
                product_variants: undefined
            }))
        };
    }
    
    // Calcul du prix total
    calculateTotal(items) {
        return items.reduce((sum, item) => sum + (item.prix * item.quantity), 0);
    }

    // Validation de stock en temps réel
    async validateStockAvailability(items) {
        console.log('🔍 Validation de stock en temps réel...');
        
        for (const item of items) {
            const { data: variant, error } = await supabase
                .from('product_variants')
                .select('stock, products(nom)')
                .eq('id', item.variant_id)
                .single();
                
            if (error) {
                throw new Error(`Variant ${item.variant_id} non trouvé`);
            }
            
            console.log(`📦 ${variant.products.nom}: stock disponible ${variant.stock}, demandé ${item.quantity}`);
            
            if (variant.stock < item.quantity) {
                throw new Error(`Stock insuffisant pour ${variant.products.nom}. Disponible: ${variant.stock}, Demandé: ${item.quantity}`);
            }
        }
        
        console.log('✅ Validation de stock réussie');
        return true;
    }
    
    // Création de commande avec validation atomique
    async createOrder(userId, orderData) {
        console.log('🚀 Création de commande avec validation atomique...');
        
        // Récupérer les prix des variantes
        const variantIds = orderData.items.map(item => item.variantId || item.variant_id);
        const { data: variants, error: variantsError } = await supabase
            .from('product_variants')
            .select('id, prix, products(prix_base)')
            .in('id', variantIds);
            
        if (variantsError) {
            throw new Error(`Erreur lors de la récupération des variantes: ${variantsError.message}`);
        }
        
        // Préparer les items au format JSONB avec les prix
        const items = orderData.items.map(item => {
            const variantId = item.variantId || item.variant_id;
            const variant = variants.find(v => v.id === variantId);
            const prix = variant?.prix || variant?.products?.prix_base || 0;
            
            return {
                variant_id: variantId,
                quantity: item.quantity,
                prix: prix
            };
        });
        
        console.log('📦 Items à commander:', JSON.stringify(items, null, 2));
        
        // Utiliser la fonction atomique
        const { data: result, error } = await supabase.rpc('create_order_with_stock_validation', {
            p_user_id: userId,
            p_items: items,
            p_adresse_livraison: orderData.adresse_livraison,
            p_methode_paiement: orderData.methode_paiement
        });
        
        if (error) {
            console.error('❌ Erreur lors de la création atomique:', error.message);
            
            // Traduire les erreurs SQL en messages utilisateur
            if (error.message.includes('Stock insuffisant')) {
                throw new Error('Stock insuffisant pour certains produits. Veuillez vérifier les quantités disponibles.');
            } else if (error.message.includes('Variant') && error.message.includes('non trouvé')) {
                throw new Error('Un ou plusieurs produits ne sont plus disponibles.');
            } else if (error.message.includes('Produits non trouvés')) {
                throw new Error('Un ou plusieurs produits ne sont plus disponibles.');
            } else if (error.message.includes('Échec de la validation du stock')) {
                // Vérifier si c'est un problème de stock ou de produit inexistant
                if (error.message.includes('Stock insuffisant pour:')) {
                    throw new Error('Stock insuffisant pour certains produits. Veuillez vérifier les quantités disponibles.');
                } else {
                    throw new Error('Un ou plusieurs produits ne sont plus disponibles ou ont un stock insuffisant.');
                }
            } else {
                throw new Error(`Erreur lors de la création de la commande: ${error.message}`);
            }
        }
        
        console.log('✅ Commande créée avec validation atomique:', result);
        return result;
    }
    
    // Annuler une commande et restaurer le stock
    async cancelOrder(orderId, userId) {
        // Vérifier que la commande existe et appartient à l'utilisateur
        const { data: order } = await supabase
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .eq('user_id', userId)
            .single();
            
        if (!order) {
            throw new Error('Commande non trouvée');
        }
        
        if (order.status !== 'En attente') {
            throw new Error('Impossible d\'annuler une commande déjà traitée');
        }
        
        // RESTAURER LE STOCK avant d'annuler la commande
        console.log('🔄 Restauration du stock pour la commande', orderId);
        const { error: restoreError } = await supabase.rpc('restore_stock', { order_id_param: orderId });
        if (restoreError) {
            console.error('❌ Erreur lors de la restauration du stock:', restoreError);
            // Continuer quand même l'annulation
        }
        
        // Mettre à jour le statut
        const { data, error } = await supabase
            .from('orders')
            .update({ status: 'Annulée' })
            .eq('id', orderId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Mettre à jour le statut d'une commande
    async updateOrderStatus(orderId, status) {
        const { data, error } = await supabase
            .from('orders')
            .update({ status })
            .eq('id', orderId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer toutes les commandes (admin)
    async getAllOrders() {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    order_id,
                    variant_id,
                    quantity,
                    unit_price,
                    product_variants (
                        *,
                        products (*),
                        colors (*),
                        heights (*)
                    )
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        // Transformer les données pour correspondre au modèle Swift
        return data.map(order => ({
            ...order,
            order_variants: order.order_variants?.map(variant => ({
                ...variant,
                product_variant: variant.product_variants,
                product_variants: undefined
            }))
        }));
    }
    
    // Récupérer les commandes d'un vendeur
    async getOrdersByVendor(vendorId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    order_id,
                    variant_id,
                    quantity,
                    unit_price,
                    product_variants (
                        *,
                        products (*),
                        colors (*),
                        heights (*)
                    )
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        // Transformer les données pour correspondre au modèle Swift
        const transformedData = data.map(order => ({
            ...order,
            order_variants: order.order_variants?.map(variant => ({
                ...variant,
                product_variant: variant.product_variants,
                product_variants: undefined
            }))
        }));
        
        // Filtrer pour ne garder que les commandes contenant des produits du vendeur
        return transformedData.filter(order => 
            order.order_variants.some(item => 
                item.product_variant.products.vendeur_id === vendorId
            )
        );
    }
    
    // Nettoyer automatiquement les commandes orphelines (timeout)
    async cleanupOrphanedOrders() {
        console.log('🧹 Nettoyage des commandes orphelines...');
        
        // Trouver les commandes en attente depuis plus de 2 minutes
        // Utiliser toISOString() pour éviter les problèmes de timezone
        const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();
        
        const { data: orphanedOrders, error } = await supabase
            .from('orders')
            .select('id, user_id')
            .eq('status', 'En attente')
            .lt('created_at', twoMinutesAgo);
            
        if (error) {
            console.error('❌ Erreur lors de la récupération des commandes orphelines:', error);
            return;
        }
        
        if (!orphanedOrders || orphanedOrders.length === 0) {
            console.log('✅ Aucune commande orpheline trouvée');
            return;
        }
        
        console.log(`🔄 Nettoyage de ${orphanedOrders.length} commande(s) orpheline(s)`);
        
        for (const order of orphanedOrders) {
            try {
                // Restaurer le stock
                const { error: restoreError } = await supabase.rpc('restore_stock', { 
                    order_id_param: order.id 
                });
                
                if (restoreError) {
                    console.error(`❌ Erreur lors de la restauration du stock pour la commande ${order.id}:`, restoreError);
                }
                
                // Marquer comme annulée
                const { error: updateError } = await supabase
                    .from('orders')
                    .update({ status: 'Annulée' })
                    .eq('id', order.id);
                    
                if (updateError) {
                    console.error(`❌ Erreur lors de la mise à jour de la commande ${order.id}:`, updateError);
                } else {
                    console.log(`✅ Commande ${order.id} nettoyée automatiquement`);
                }
                
            } catch (error) {
                console.error(`❌ Erreur lors du nettoyage de la commande ${order.id}:`, error);
            }
        }
        
        console.log('✅ Nettoyage des commandes orphelines terminé');
    }
    
    // Démarrer le nettoyage automatique (à appeler au démarrage du serveur)
    startAutoCleanup() {
        // Nettoyer toutes les 30 secondes (plus fréquent pour 2 min de timeout)
        setInterval(() => {
            this.cleanupOrphanedOrders();
        }, 30 * 1000);
        
        console.log('🔄 Nettoyage automatique des commandes orphelines activé (toutes les 30 secondes)');
    }
}

module.exports = new OrderService(); 