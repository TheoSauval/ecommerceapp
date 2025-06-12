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
    },
    user_id: {
        type: DataTypes.INTEGER,
        references: { model: 'users', key: 'id' },
        allowNull: true,
        unique: true
    }
}, {
    timestamps: true
});

module.exports = Vendeur;