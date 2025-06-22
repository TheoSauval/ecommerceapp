const { supabase } = require('../config/supabase');

class CartService {
    // Récupérer le panier d'un utilisateur avec les détails des produits
    async getCart(userId) {
        const { data, error } = await supabase
            .from('cart_items')
            .select(`
                *,
                product_variants (
                    *,
                    products (*),
                    colors (*),
                    heights (*)
                )
            `)
            .eq('user_id', userId);

        if (error) {
            console.error('Error fetching cart:', error);
            throw new Error('Impossible de récupérer le panier.');
        }

        // Le nom de la jointure est 'product_variants', nous le renommons en 'product_variant' pour correspondre au modèle Swift
        return data.map(item => ({
            ...item,
            product_variant: item.product_variants,
            product_variants: undefined // Supprimer l'ancien champ
        }));
    }

    // Ajouter un produit au panier
    async addToCart(userId, variantId, quantity) {
        if (!variantId || !quantity || quantity <= 0) {
            throw new Error('ID de variante et quantité sont requis.');
        }

        const { data: existingItem, error: findError } = await supabase
            .from('cart_items')
            .select('*')
            .eq('user_id', userId)
            .eq('variant_id', variantId)
            .single();

        if (findError && findError.code !== 'PGRST116') { // 'PGRST116' = 'Not a single row' (c-a-d item non trouvé)
            throw findError;
        }

        if (existingItem) {
            const newQuantity = existingItem.quantity + quantity;
            const { data, error } = await supabase
                .from('cart_items')
                .update({ quantity: newQuantity })
                .eq('id', existingItem.id)
                .select()
                .single();
            if (error) throw error;
            return { message: 'Quantité mise à jour', item: data };
        } else {
            const { data, error } = await supabase
                .from('cart_items')
                .insert([{ user_id: userId, variant_id: variantId, quantity }])
                .select()
                .single();
            if (error) throw error;
            return { message: 'Produit ajouté au panier', item: data };
        }
    }

    // Mettre à jour un élément du panier
    async updateCartItem(cartItemId, userId, quantity) {
        if (quantity <= 0) {
            return this.removeFromCart(cartItemId, userId);
        }

        const { data, error } = await supabase
            .from('cart_items')
            .update({ quantity })
            .eq('id', cartItemId)
            .eq('user_id', userId)
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    // Supprimer un élément du panier
    async removeFromCart(cartItemId, userId) {
        const { error } = await supabase
            .from('cart_items')
            .delete()
            .eq('id', cartItemId)
            .eq('user_id', userId);
        if (error) throw error;
        return { message: 'Item retiré du panier' };
    }

    // Vider le panier d'un utilisateur
    async clearCart(userId) {
        const { error } = await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId);
        if (error) throw error;
        return { message: 'Panier vidé' };
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