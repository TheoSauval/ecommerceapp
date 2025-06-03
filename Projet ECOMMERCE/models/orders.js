const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

// models/Commande.js
const Commande = sequelize.define('order', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    prix_total: { type: DataTypes.DECIMAL(10,2), allowNull: false },
    status: { type: DataTypes.ENUM('En attente', 'Expédiée', 'Livrée', 'Annulée'), allowNull: false },
    user_id: { type: DataTypes.INTEGER, references: { model: 'Users', key: 'id' } }
}, { timestamps: true });

module.exports = Commande;