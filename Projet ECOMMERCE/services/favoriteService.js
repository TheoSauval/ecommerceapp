const { supabase } = require('../config/supabase');

class FavoriteService {
    // Récupérer les favoris d'un utilisateur
    async getFavorites(userId) {
        const { data, error } = await supabase
            .from('favorites')
            .select(`
                product_id,
                products (
                    id,
                    nom,
                    prix_base,
                    vendeur_id,
                    description,
                    categorie,
                    marque,
                    images,
                    actif,
                    created_at,
                    updated_at
                )
            `)
            .eq('user_id', userId);

        if (error) throw error;
        // On s'assure de ne renvoyer que les produits qui ne sont pas null
        return data.map(fav => fav.products).filter(p => p !== null);
    }

    // Ajouter un produit aux favoris
    async addFavorite(userId, productId) {
        // Vérifier si le produit existe
        const { data: product } = await supabase
            .from('products')
            .select('id')
            .eq('id', productId)
            .single();

        if (!product) {
            throw new Error('Produit non trouvé');
        }

        // Vérifier si le produit est déjà dans les favoris
        const { data: existingFavorite } = await supabase
            .from('favorites')
            .select('*')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .single();

        if (existingFavorite) {
            throw new Error('Produit déjà dans les favoris');
        }

        // Ajouter aux favoris
        const { error } = await supabase
            .from('favorites')
            .insert([{
                user_id: userId,
                product_id: productId
            }]);

        if (error) throw error;
        return { message: 'Produit ajouté aux favoris' };
    }

    // Retirer un produit des favoris
    async removeFavorite(userId, productId) {
        // Vérifier si le produit existe dans les favoris
        const { data: favorite } = await supabase
            .from('favorites')
            .select('*')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .single();

        if (!favorite) {
            throw new Error('Produit non trouvé dans les favoris');
        }

        // Retirer des favoris
        const { error } = await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);

        if (error) throw error;
        return { message: 'Produit retiré des favoris' };
    }

    // Vérifier si un produit est dans les favoris
    async isFavorite(userId, productId) {
        const { data } = await supabase
            .from('favorites')
            .select('*')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .single();

        return !!data;
    }

    // Compter le nombre de favoris d'un utilisateur
    async getFavoriteCount(userId) {
        const { count, error } = await supabase
            .from('favorites')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId);

        if (error) throw error;
        return count || 0;
    }
}

module.exports = new FavoriteService(); 