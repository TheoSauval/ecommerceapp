const { supabase } = require('../config/supabase');

class CartService {
    // Récupérer le panier d'un utilisateur avec les détails des produits
    async getCart(userId) {
        const { data, error } = await supabase
            .from('cart_items')
            .select(`
                *,
                products (
                    id,
                    nom,
                    prix,
                    quantite
                )
            `)
            .eq('user_id', userId);
            
        if (error) throw error;
        return { items: data };
    }
    
    // Ajouter un produit au panier
    async addToCart(userId, productId, quantity, size, color) {
        // Vérifier si le produit existe
        const { data: product } = await supabase
            .from('products')
            .select('id')
            .eq('id', productId)
            .single();
            
        if (!product) {
            throw new Error('Produit non trouvé');
        }
        
        // Vérifier si l'item existe déjà dans le panier
        const { data: existingItem } = await supabase
            .from('cart_items')
            .select('*')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .eq('size', size)
            .eq('color', color)
            .single();
            
        if (existingItem) {
            // Mettre à jour la quantité si l'item existe déjà
            const { data, error } = await supabase
                .from('cart_items')
                .update({ quantity: existingItem.quantity + quantity })
                .eq('id', existingItem.id)
                .select()
                .single();
                
            if (error) throw error;
            
            return {
                message: 'Quantité mise à jour dans le panier',
                cartItemId: data.id
            };
        }
        
        // Créer un nouvel item dans le panier
        const { data: cartItem, error } = await supabase
            .from('cart_items')
            .insert([{
                user_id: userId,
                product_id: productId,
                quantity,
                size,
                color
            }])
            .select()
            .single();
            
        if (error) throw error;
        
        return {
            message: 'Produit ajouté au panier',
            cartItemId: cartItem.id
        };
    }
    
    // Mettre à jour un élément du panier
    async updateCartItem(itemId, userId, updates) {
        const { data, error } = await supabase
            .from('cart_items')
            .update(updates)
            .eq('id', itemId)
            .eq('user_id', userId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Supprimer un élément du panier
    async removeFromCart(itemId, userId) {
        const { error } = await supabase
            .from('cart_items')
            .delete()
            .eq('id', itemId)
            .eq('user_id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Vider le panier d'un utilisateur
    async clearCart(userId) {
        const { error } = await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Récupérer un élément du panier par ID
    async getCartItemById(itemId, userId) {
        const { data, error } = await supabase
            .from('cart_items')
            .select(`
                *,
                products (
                    id,
                    nom,
                    prix,
                    quantite
                )
            `)
            .eq('id', itemId)
            .eq('user_id', userId)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Calculer le total du panier
    async getCartTotal(userId) {
        const { data: cartItems } = await supabase
            .from('cart_items')
            .select(`
                quantity,
                products (
                    prix
                )
            `)
            .eq('user_id', userId);
            
        if (!cartItems) return 0;
        
        return cartItems.reduce((total, item) => {
            return total + (item.products.prix * item.quantity);
        }, 0);
    }
    
    // Vérifier la disponibilité des produits dans le panier
    async checkCartAvailability(userId) {
        const { data: cartItems } = await supabase
            .from('cart_items')
            .select(`
                quantity,
                products (
                    id,
                    nom,
                    quantite
                )
            `)
            .eq('user_id', userId);
            
        const unavailableItems = [];
        
        for (const item of cartItems) {
            if (item.quantity > item.products.quantite) {
                unavailableItems.push({
                    productId: item.products.id,
                    productName: item.products.nom,
                    requestedQuantity: item.quantity,
                    availableQuantity: item.products.quantite
                });
            }
        }
        
        return {
            available: unavailableItems.length === 0,
            unavailableItems
        };
    }
}

module.exports = new CartService(); 