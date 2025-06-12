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
        references: { model: 'vendors', key: 'id' },
        allowNull: false
    },
    description: {
        type: DataTypes.STRING,
        allowNull: true
    },
    categorie: {
        type: DataTypes.STRING,
        allowNull: true
    },
    marque: {
        type: DataTypes.STRING,
        allowNull: true
    },
    images: {
        type: DataTypes.JSON,
        allowNull: true
    }
}, {
    timestamps: true
});

module.exports = Produit;