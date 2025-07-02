const productService = require('../services/productService');

// GET /api/products
exports.getAllProducts = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;

        const result = await productService.getAllProducts(page, limit);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/products/search
exports.searchProducts = async (req, res) => {
    try {
        const { q } = req.query;
        const products = await productService.searchProducts(q);
        res.json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/products/:id
exports.getProductById = async (req, res) => {
    try {
        const product = await productService.getProductById(req.params.id);
        res.json(product);
    } catch (error) {
        res.status(404).json({ message: 'Produit non trouvé' });
    }
};

// POST /api/products
exports.createProduct = async (req, res) => {
    try {
        const product = await productService.createProduct(req.body);
        res.status(201).json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/products/:id
exports.updateProduct = async (req, res) => {
    try {
        const product = await productService.updateProduct(req.params.id, req.body);
        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/products/:id
exports.deleteProduct = async (req, res) => {
    try {
        await productService.deleteProduct(req.params.id);
        res.json({ message: 'Produit supprimé' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/products/categories
exports.getAvailableCategories = async (req, res) => {
    try {
        const categories = await productService.getAvailableCategories();
        res.json(categories);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/products/category/:category
exports.getProductsByCategory = async (req, res) => {
    try {
        const { category } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;

        const result = await productService.getProductsByCategory(category, page, limit);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 