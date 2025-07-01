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
    
    // Créer une nouvelle commande
    async createOrder(userId, orderData) {
        console.log('orderService.createOrder appelé avec:', userId, orderData);
        const { items, adresse_livraison, methode_paiement } = orderData;
        
        // Récupérer les variantes
        const variantIds = items.map(item => item.variantId);
        const { data: variants, error: variantsError } = await supabase
            .from('product_variants')
            .select('*, products (id, prix_base)')
            .in('id', variantIds);
        if (variantsError) throw variantsError;
        if (!variants || variants.length !== variantIds.length) {
            throw new Error('Une ou plusieurs variantes sont introuvables');
        }
        
        // Vérifier le stock disponible
        for (const variant of variants) {
            const item = items.find(i => i.variantId === variant.id);
            if (variant.stock < item.quantity) {
                throw new Error(`Stock insuffisant pour la variante ${variant.id}. Disponible: ${variant.stock}, Demandé: ${item.quantity}`);
            }
        }
        
        // Calculer le prix total avec le prix de la variante
        const prix_total = variants.reduce((sum, variant) => {
            const item = items.find(i => i.variantId === variant.id);
            const prix = variant.prix !== undefined && variant.prix !== null ? variant.prix : (variant.products?.prix_base ?? 0);
            return sum + prix * item.quantity;
        }, 0);
        
        // Créer la commande
        const { data: order, error: orderError } = await supabase
            .from('orders')
            .insert([{
                user_id: userId,
                status: 'En attente',
                adresse_livraison,
                methode_paiement,
                prix_total
            }])
            .select('*')
            .single();
        console.log('TRUC DE DEBUG - Résultat insert commande:', { order, orderError });
        if (orderError) throw orderError;
        
        // Créer les lignes dans order_variants
        const orderVariants = variants.map(variant => {
            const item = items.find(i => i.variantId === variant.id);
            const prix = variant.prix !== undefined && variant.prix !== null ? variant.prix : (variant.products?.prix_base ?? 0);
            return {
                order_id: order.id,
                variant_id: variant.id,
                quantity: item.quantity,
                unit_price: prix
            };
        });
        const { error: orderVariantsError } = await supabase
            .from('order_variants')
            .insert(orderVariants);
        if (orderVariantsError) throw orderVariantsError;
        
        // NE PAS décrémenter le stock ici - cela se fera après paiement réussi via webhook
        
        return order;
    }
    
    // Annuler une commande
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
}

module.exports = new OrderService(); 