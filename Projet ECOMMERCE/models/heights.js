const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

// models/Heights.js
const Heights = sequelize.define('height', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    produit_id: { type: DataTypes.INTEGER, references: { model: 'products', key: 'id' } },
    taille: { type: DataTypes.STRING, allowNull: false }
}, { timestamps: true });

module.exports = Heights;