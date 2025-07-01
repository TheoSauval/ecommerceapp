const { supabase } = require('../config/supabase');

class ProductService {
    // Récupérer tous les produits avec pagination
    async getAllProducts(page = 1, limit = 10) {
        const offset = (page - 1) * limit;

        // Récupérer le total des produits actifs
        const { count, error: countError } = await supabase
            .from('products')
            .select('*', { count: 'exact', head: true })
            .eq('actif', true);

        if (countError) throw countError;

        // Récupérer les produits actifs avec leurs variantes
        const { data: products, error } = await supabase
            .from('products')
            .select(`
                *,
                product_variants (
                    *,
                    colors (id, nom, code_hex),
                    heights (id, nom, ordre)
                )
            `)
            .eq('actif', true)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) throw error;

        // Renommer 'product_variants' en 'variants' pour la compatibilité avec le client Swift
        const productsWithRenamedVariants = products.map(p => ({
            ...p,
            variants: p.product_variants || [],
            product_variants: undefined // Nettoyage
        }));

        return {
            products: productsWithRenamedVariants,
            totalPages: Math.ceil(count / limit),
            currentPage: page
        };
    }

    // Rechercher des produits
    async searchProducts(query) {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .ilike('nom', `%${query}%`)
            .order('created_at', { ascending: false });

        if (error) throw error;
        return data;
    }

    // Récupérer un produit par ID avec ses variantes
    async getProductById(id) {
        const { data: product, error: productError } = await supabase
            .from('products')
            .select('*')
            .eq('id', id)
            .single();

        if (productError) throw productError;

        // Récupérer les variantes du produit
        const { data: variants, error: variantsError } = await supabase
            .from('product_variants')
            .select(`
                *,
                colors (id, nom, code_hex),
                heights (id, nom, ordre)
            `)
            .eq('product_id', id)
            .eq('actif', true);

        if (variantsError) throw variantsError;

        return {
            ...product,
            variants: variants || []
        };
    }

    // Créer un nouveau produit
    async createProduct(productData) {
        const { data, error } = await supabase
            .from('products')
            .insert([productData])
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Mettre à jour un produit
    async updateProduct(id, updates) {
        const { data, error } = await supabase
            .from('products')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Supprimer un produit
    async deleteProduct(id) {
        const { error } = await supabase
            .from('products')
            .delete()
            .eq('id', id);

        if (error) throw error;
        return true;
    }

    // Récupérer les produits d'un vendeur avec leurs variantes
    async getProductsByVendor(vendorId) {
        const { data: products, error: productsError } = await supabase
            .from('products')
            .select('*')
            .eq('vendeur_id', vendorId)
            .order('created_at', { ascending: false });

        if (productsError) throw productsError;

        // Pour chaque produit, récupérer ses variantes
        const productsWithVariants = await Promise.all(
            products.map(async (product) => {
                const { data: variants, error: variantsError } = await supabase
                    .from('product_variants')
                    .select(`
                        *,
                        colors (nom, code_hex),
                        heights (nom, ordre)
                    `)
                    .eq('product_id', product.id)
                    .eq('actif', true);

                if (variantsError) throw variantsError;

                return {
                    ...product,
                    variants: variants || []
                };
            })
        );

        return productsWithVariants;
    }

    // Récupérer toutes les couleurs disponibles
    async getAllColors() {
        const { data, error } = await supabase
            .from('colors')
            .select('*')
            .order('nom');

        if (error) throw error;
        return data;
    }

    // Récupérer toutes les tailles disponibles
    async getAllHeights() {
        const { data, error } = await supabase
            .from('heights')
            .select('*')
            .order('ordre');

        if (error) throw error;
        return data;
    }

    // Créer une variante de produit
    async createProductVariant(variantData) {
        const { data, error } = await supabase
            .from('product_variants')
            .insert([variantData])
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Mettre à jour une variante de produit
    async updateProductVariant(variantId, updates) {
        const { data, error } = await supabase
            .from('product_variants')
            .update(updates)
            .eq('id', variantId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Supprimer une variante de produit
    async deleteProductVariant(variantId) {
        const { error } = await supabase
            .from('product_variants')
            .delete()
            .eq('id', variantId);

        if (error) throw error;
        return true;
    }

    // Récupérer les variantes d'un produit
    async getProductVariants(productId) {
        const { data, error } = await supabase
            .from('product_variants')
            .select(`
                *,
                colors (nom, code_hex),
                heights (nom, ordre)
            `)
            .eq('product_id', productId)
            .eq('actif', true);

        if (error) throw error;
        return data;
    }

    // Récupérer les variantes d'un produit qui ont des commandes associées
    async getVariantsWithOrders(productId) {
        // D'abord, récupérer les IDs des variantes du produit
        const { data: variantIds, error: variantsError } = await supabase
            .from('product_variants')
            .select('id')
            .eq('product_id', productId);

        if (variantsError) throw variantsError;
        if (!variantIds || variantIds.length === 0) return [];

        // Ensuite, vérifier quelles variantes ont des commandes
        const { data: ordersData, error: ordersError } = await supabase
            .from('order_variants')
            .select('variant_id')
            .in('variant_id', variantIds.map(v => v.id));

        if (ordersError) throw ordersError;
        return ordersData || [];
    }
}

module.exports = new ProductService(); 