const { Produit, Colors, Heights } = require('../models');

// GET /api/admin/products
exports.getAllProducts = async (req, res) => {
    try {
        const products = await Produit.findAll({
            where: { vendeur_id: req.user.id },
            include: [
                { model: Colors },
                { model: Heights }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/products/:id
exports.getProductById = async (req, res) => {
    try {
        const product = await Produit.findOne({
            where: {
                id: req.params.id,
                vendeur_id: req.user.id
            },
            include: [
                { model: Colors },
                { model: Heights }
            ]
        });
        if (!product) {
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
        const { nom, prix, quantite, description, categorie, marque, images } = req.body;
        const product = await Produit.create({
            nom,
            prix,
            quantite,
            description,
            categorie,
            marque,
            images,
            vendeur_id: req.user.id
        });
        res.status(201).json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/admin/products/:id
exports.updateProduct = async (req, res) => {
    try {
        const product = await Produit.findOne({
            where: {
                id: req.params.id,
                vendeur_id: req.user.id
            }
        });
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        const { nom, prix, quantite, description, categorie, marque, images } = req.body;
        await product.update({
            nom,
            prix,
            quantite,
            description,
            categorie,
            marque,
            images
        });
        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/admin/products/:id
exports.deleteProduct = async (req, res) => {
    try {
        const product = await Produit.findOne({
            where: {
                id: req.params.id,
                vendeur_id: req.user.id
            }
        });
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        await product.destroy();
        res.json({ message: 'Produit supprimé avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/admin/products/:id/heights
exports.addHeight = async (req, res) => {
    try {
        const product = await Produit.findOne({
            where: {
                id: req.params.id,
                vendeur_id: req.user.id
            }
        });
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        const height = await Heights.create({
            produit_id: product.id,
            taille: req.body.hauteur
        });
        res.status(201).json(height);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/admin/products/:id/heights/:hid
exports.removeHeight = async (req, res) => {
    try {
        const height = await Heights.findOne({
            where: {
                id: req.params.hid,
                produit_id: req.params.id
            }
        });
        if (!height) {
            return res.status(404).json({ message: 'Taille non trouvée' });
        }
        await height.destroy();
        res.json({ message: 'Taille supprimée avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/admin/products/:id/colors
exports.addColor = async (req, res) => {
    try {
        const product = await Produit.findOne({
            where: {
                id: req.params.id,
                vendeur_id: req.user.id
            }
        });
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        const color = await Colors.create({
            produit_id: product.id,
            couleur: req.body.couleur
        });
        res.status(201).json(color);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/admin/products/:id/colors/:cid
exports.removeColor = async (req, res) => {
    try {
        const color = await Colors.findOne({
            where: {
                id: req.params.cid,
                produit_id: req.params.id
            }
        });
        if (!color) {
            return res.status(404).json({ message: 'Couleur non trouvée' });
        }
        await color.destroy();
        res.json({ message: 'Couleur supprimée avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 