const { Sequelize } = require('sequelize');
require('dotenv').config();

// 1) Connexion à la base de données MySQL
const db = new Sequelize(process.env.DB_NAME, process.env.DB_USER, process.env.DB_PASS, {
    host: process.env.DB_HOST,
    dialect: 'mysql',
    port: process.env.DB_PORT,
    pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
    },
    transactionType: 'IMMEDIATE',
    isolationLevel: 'READ COMMITTED'
});

// 2) Test de la connexion
const connection = () =>  {
    db.authenticate()
    .then(() => {
        console.log('La connexion à la base de données à bien été établie.');
    })
    .catch(err => {
        console.error('Impossible de se connecter à la base de donnée:', err);
    });
}

connection();

module.exports = db;