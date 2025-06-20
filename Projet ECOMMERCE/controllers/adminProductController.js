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
            // Supprimer toutes les variantes existantes
            const existingVariants = await productService.getProductVariants(req.params.id);
            for (const variant of existingVariants) {
                await productService.deleteProductVariant(variant.id);
            }

            // Créer les nouvelles variantes
            for (const variant of variants) {
                await productService.createProductVariant({
                    product_id: req.params.id,
                    color_id: variant.color_id,
                    height_id: variant.height_id,
                    stock: variant.stock || 0,
                    prix: variant.prix || null
                });
            }
        }

        // Récupérer le produit mis à jour avec ses variantes
        const productWithVariants = await productService.getProductById(req.params.id);
        res.json(productWithVariants);
    } catch (error) {
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