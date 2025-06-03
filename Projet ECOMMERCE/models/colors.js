const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

// models/Colors.js
const Colors = sequelize.define('color', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    produit_id: { type: DataTypes.INTEGER, references: { model: 'products', key: 'id' } },
    couleur: { type: DataTypes.STRING, allowNull: false }
}, { timestamps: true });

module.exports = Colors;