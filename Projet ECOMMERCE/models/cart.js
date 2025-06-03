const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Panier = sequelize.define('panier', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    user_id: { type: DataTypes.INTEGER, references: { model: 'users', key: 'id' } },
    produit_id: { type: DataTypes.INTEGER, references: { model: 'products', key: 'id' } },
    quantite: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 1 },
    taille: { type: DataTypes.STRING, allowNull: true },
    couleur: { type: DataTypes.STRING, allowNull: true }
}, { timestamps: true });

module.exports = Panier; 