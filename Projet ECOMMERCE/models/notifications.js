const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');


// models/Notification.js
const Notification = sequelize.define('notification', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    user_id: { type: DataTypes.INTEGER, references: { model: 'users', key: 'id' } },
    status: { type: DataTypes.STRING, allowNull: false }
}, { timestamps: false });

module.exports = Notification;