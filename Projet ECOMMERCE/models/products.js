const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');



// models/Produit.js
const Produit = sequelize.define('product', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    nom: {
        type: DataTypes.STRING,
        allowNull: false
    },
    prix: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false
    },
    quantite: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: { min: 0 }
    },
    vendeur_id: {
        type: DataTypes.INTEGER,
        references: { model: 'vendors', key: 'id' }
    }
}, {
    timestamps: true
});

module.exports = Produit;