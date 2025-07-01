const productService = require('../services/productService');
const userService = require('../services/userService');

// GET /api/admin/products
exports.getAllProducts = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        const products = await productService.getProductsByVendor(vendor.id);
        res.json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/products/:id
exports.getProductById = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        const product = await productService.getProductById(req.params.id);
        if (!product || product.vendeur_id !== vendor.id) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/admin/products
exports.createProduct = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        
        const { nom, prix_base, description, categorie, marque, images, variants } = req.body;
        
        // Créer le produit
        const product = await productService.createProduct({
            nom,
            prix_base: Number(prix_base),
            description,
            categorie,
            marque,
            images,
            vendeur_id: vendor.id
        });

        // Créer les variantes si fournies
        if (variants && Array.isArray(variants)) {
            for (const variant of variants) {
                await productService.createProductVariant({
                    product_id: product.id,
                    color_id: variant.color_id,
                    height_id: variant.height_id,
                    stock: variant.stock || 0,
                    prix: variant.prix || null
                });
            }
        }

        // Récupérer le produit avec ses variantes
        const productWithVariants = await productService.getProductById(product.id);
        res.status(201).json(productWithVariants);
    } catch (error) {
        console.error('Erreur lors de la création du produit:', error);
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/admin/products/:id
exports.updateProduct = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        const product = await productService.getProductById(req.params.id);
        if (!product || product.vendeur_id !== vendor.id) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        
        const { nom, prix_base, description, categorie, marque, images, variants } = req.body;
        
        // Mettre à jour le produit
        const updatedProduct = await productService.updateProduct(req.params.id, {
            nom,
            prix_base: Number(prix_base),
            description,
            categorie,
            marque,
            images
        });

        // Mettre à jour les variantes si fournies
        if (variants && Array.isArray(variants)) {
            // Récupérer les variantes existantes
            const existingVariants = await productService.getProductVariants(req.params.id);
            
            // Vérifier quelles variantes ont des commandes associées
            const variantsWithOrders = await productService.getVariantsWithOrders(req.params.id);
            const variantsWithOrdersIds = new Set(variantsWithOrders.map(v => v.variant_id));
            
            console.log('🔍 Variantes avec commandes:', Array.from(variantsWithOrdersIds));
            
            // Traiter chaque variante existante
            for (const existingVariant of existingVariants) {
                const hasOrders = variantsWithOrdersIds.has(existingVariant.id);
                
                // Chercher si cette variante existe dans les nouvelles données
                const matchingNewVariant = variants.find(v => 
                    v.color_id === existingVariant.color_id && 
                    v.height_id === existingVariant.height_id
                );
                
                if (matchingNewVariant) {
                    // Variante trouvée dans les nouvelles données - mise à jour
                    if (hasOrders) {
                        // Si la variante a des commandes, on ne met à jour que le stock et le prix
                        console.log(`📦 Mise à jour sécurisée de la variante ${existingVariant.id} (avec commandes)`);
                        await productService.updateProductVariant(existingVariant.id, {
                            stock: matchingNewVariant.stock || 0,
                            prix: matchingNewVariant.prix || null
                        });
                    } else {
                        // Si pas de commandes, on peut tout mettre à jour
                        console.log(`🔄 Mise à jour complète de la variante ${existingVariant.id} (sans commandes)`);
                        await productService.updateProductVariant(existingVariant.id, {
                            color_id: matchingNewVariant.color_id,
                            height_id: matchingNewVariant.height_id,
                            stock: matchingNewVariant.stock || 0,
                            prix: matchingNewVariant.prix || null
                        });
                    }
                } else {
                    // Variante non trouvée dans les nouvelles données
                    if (hasOrders) {
                        // Si la variante a des commandes, on la désactive au lieu de la supprimer
                        console.log(`⚠️ Désactivation de la variante ${existingVariant.id} (avec commandes - préservation)`);
                        await productService.updateProductVariant(existingVariant.id, {
                            actif: false
                        });
                    } else {
                        // Si pas de commandes, on peut la supprimer
                        console.log(`🗑️ Suppression de la variante ${existingVariant.id} (sans commandes)`);
                        await productService.deleteProductVariant(existingVariant.id);
                    }
                }
            }
            
            // Créer les nouvelles variantes qui n'existent pas encore
            for (const newVariant of variants) {
                const variantExists = existingVariants.some(v => 
                    v.color_id === newVariant.color_id && 
                    v.height_id === newVariant.height_id
                );
                
                if (!variantExists) {
                    console.log(`➕ Création de la nouvelle variante: ${newVariant.color_id}-${newVariant.height_id}`);
                    await productService.createProductVariant({
                        product_id: req.params.id,
                        color_id: newVariant.color_id,
                        height_id: newVariant.height_id,
                        stock: newVariant.stock || 0,
                        prix: newVariant.prix || null
                    });
                }
            }
        }

        // Récupérer le produit mis à jour avec ses variantes
        const productWithVariants = await productService.getProductById(req.params.id);
        res.json(productWithVariants);
    } catch (error) {
        console.error('❌ Erreur lors de la mise à jour du produit:', error);
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/admin/products/:id
exports.deleteProduct = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        const product = await productService.getProductById(req.params.id);
        if (!product || product.vendeur_id !== vendor.id) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        await productService.deleteProduct(req.params.id);
        res.json({ message: 'Produit supprimé avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/products/colors
exports.getAllColors = async (req, res) => {
    try {
        const colors = await productService.getAllColors();
        res.json(colors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/products/heights
exports.getAllHeights = async (req, res) => {
    try {
        const heights = await productService.getAllHeights();
        res.json(heights);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/admin/products/:id/variants
exports.addVariant = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        const product = await productService.getProductById(req.params.id);
        if (!product || product.vendeur_id !== vendor.id) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        
        const { color_id, height_id, stock, prix } = req.body;
        const variant = await productService.createProductVariant({
            product_id: req.params.id,
            color_id,
            height_id,
            stock: stock || 0,
            prix: prix || null
        });
        res.status(201).json(variant);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/admin/products/:id/variants/:variantId
exports.removeVariant = async (req, res) => {
    try {
        await productService.deleteProductVariant(req.params.variantId);
        res.json({ message: 'Variante supprimée avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 