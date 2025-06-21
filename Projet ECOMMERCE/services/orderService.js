const { supabase } = require('../config/supabase');

class OrderService {
    // Récupérer toutes les commandes d'un utilisateur
    async getOrders(userId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    quantity,
                    unit_price,
                    product_variants (
                        id,
                        products (
                            id,
                            nom,
                            prix_base,
                            description
                        ),
                        colors (
                            nom
                        ),
                        heights (
                            nom
                        )
                    )
                )
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer une commande par ID
    async getOrderById(orderId, userId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    quantity,
                    unit_price,
                    product_variants (
                        id,
                        products (
                            id,
                            nom,
                            prix_base,
                            description
                        ),
                        colors (
                            nom
                        ),
                        heights (
                            nom
                        )
                    )
                )
            `)
            .eq('id', orderId)
            .eq('user_id', userId)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Créer une nouvelle commande
    async createOrder(userId, orderData) {
        const { items, adresse_livraison, methode_paiement } = orderData;
        
        // Vérifier que tous les produits existent et sont en stock
        const productIds = items.map(item => item.productId);
        const { data: products } = await supabase
            .from('products')
            .select('*')
            .in('id', productIds);
            
        if (products.length !== productIds.length) {
            throw new Error('Un ou plusieurs produits n\'existent pas');
        }
        
        // Vérifier le stock
        for (const product of products) {
            const item = items.find(i => i.productId === product.id);
            if (product.quantite < item.quantity) {
                throw new Error(`Stock insuffisant pour ${product.nom}`);
            }
        }
        
        // Calculer le prix total
        const prix_total = products.reduce((sum, product) => {
            const item = items.find(i => i.productId === product.id);
            return sum + product.prix * item.quantity;
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
            .select()
            .single();
            
        if (orderError) throw orderError;
        
        // Ajouter les produits à la commande
        const orderItems = products.map(product => {
            const item = items.find(i => i.productId === product.id);
            return {
                order_id: order.id,
                product_id: product.id,
                quantity: item.quantity,
                unit_price: product.prix
            };
        });
        
        const { error: itemsError } = await supabase
            .from('orders_products')
            .insert(orderItems);
            
        if (itemsError) throw itemsError;
        
        // Mettre à jour le stock
        for (const product of products) {
            const item = items.find(i => i.productId === product.id);
            const { error: stockError } = await supabase
                .from('products')
                .update({ quantite: product.quantite - item.quantity })
                .eq('id', product.id);
                
            if (stockError) throw stockError;
        }
        
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
                    quantity,
                    unit_price,
                    product_variants (
                        id,
                        products (
                            id,
                            nom,
                            prix_base
                        ),
                        colors (
                            nom
                        ),
                        heights (
                            nom
                        )
                    )
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer les commandes d'un vendeur
    async getOrdersByVendor(vendorId) {
        const { data, error } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    quantity,
                    unit_price,
                    product_variants (
                        id,
                        products (
                            id,
                            nom,
                            prix_base,
                            vendeur_id
                        ),
                        colors (
                            nom
                        ),
                        heights (
                            nom
                        )
                    )
                )
            `)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        
        // Filtrer pour ne garder que les commandes contenant des produits du vendeur
        return data.filter(order => 
            order.order_variants.some(item => 
                item.product_variants.products.vendeur_id === vendorId
            )
        );
    }
}

module.exports = new OrderService(); 