const sequelize = require('../config/database');

const User = require('../models/users');
const Vendeur = require('../models/vendors');
const Produit = require('../models/products');
const Commande = require('../models/orders');
const Paiement = require('../models/payments');
const Notification = require('../models/notifications');
const Colors = require('../models/colors');
const Heights = require('../models/heights');
const CartItem = require('../models/cartItem');
const Favorite = require('../models/favorites');

// Définition des relations
Vendeur.hasMany(Produit, { foreignKey: 'vendeur_id' });
Produit.belongsTo(Vendeur, { foreignKey: 'vendeur_id' });

User.hasMany(Commande, { foreignKey: 'user_id' });
Commande.belongsTo(User, { foreignKey: 'user_id' });

Commande.belongsToMany(Produit, { through: 'orders_products' });
Produit.belongsToMany(Commande, { through: 'orders_products' });

Produit.hasMany(Paiement, { foreignKey: 'produit_id' });
Paiement.belongsTo(Produit, { foreignKey: 'produit_id' });

User.hasMany(Notification, { foreignKey: 'user_id' });
Notification.belongsTo(User, { foreignKey: 'user_id' });

Produit.hasMany(Colors, { foreignKey: 'produit_id' });
Colors.belongsTo(Produit, { foreignKey: 'produit_id' });

Produit.hasMany(Heights, { foreignKey: 'produit_id' });
Heights.belongsTo(Produit, { foreignKey: 'produit_id' });

// Association pour le panier
User.hasMany(CartItem, { foreignKey: 'UserId' });
CartItem.belongsTo(User, { foreignKey: 'UserId' });

Produit.hasMany(CartItem, { foreignKey: 'ProductId' });
CartItem.belongsTo(Produit, { foreignKey: 'ProductId' });

User.belongsToMany(Produit, { as: 'Favorites', through: Favorite, foreignKey: 'user_id' });
Produit.belongsToMany(User, { as: 'FavoredBy', through: Favorite, foreignKey: 'product_id' });

module.exports = {
    sequelize,
    User,
    Vendeur,
    Produit,
    Commande,
    Paiement,
    Notification,
    Colors,
    Heights,
    CartItem,
    Favorite
};
