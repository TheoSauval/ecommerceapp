const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');


// models/Vendeur.js
const Vendeur = sequelize.define('vendors', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    nom: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    timestamps: true
});

module.exports = Vendeur;