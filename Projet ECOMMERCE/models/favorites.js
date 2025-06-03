const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Favorite = sequelize.define('favorites', {}, { timestamps: false });

module.exports = Favorite; 