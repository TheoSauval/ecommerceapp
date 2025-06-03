const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');


// models/Paiement.js
const Paiement = sequelize.define('payment', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    produit_id: { type: DataTypes.INTEGER, references: { model: 'products', key: 'id' } },
    prix_total: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    status: { type: DataTypes.ENUM('En attente', 'Payé', 'Remboursé'), allowNull: false },
    date_paiement: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { timestamps: true });

module.exports = Paiement;