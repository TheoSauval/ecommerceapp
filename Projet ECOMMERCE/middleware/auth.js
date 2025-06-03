// middleware/auth.js
const jwt = require('jsonwebtoken');
const { User } = require('../models');

// 1) Middleware d'authentification
//    Vérifie que le token est présent et valide
//    Si oui, ajoute l'utilisateur dans req.user
//    Sinon, renvoie une erreur 401
module.exports = (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header) {
    return res.status(401).json({ message: 'Token manquant' });
  }

  const [, token] = header.split(' ');
  if (!token) {
    return res.status(401).json({ message: 'Token mal formé' });
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, payload) => {
    if (err) {
      return res.status(401).json({ message: 'Token invalide' });
    }
    
    // Récupérer l'utilisateur complet depuis la base de données
    const user = await User.findByPk(payload.id);
    if (!user) {
      return res.status(401).json({ message: 'Utilisateur non trouvé' });
    }
    
    req.user = user; // Stocker l'utilisateur complet
    next();
  });
};

// Middleware pour vérifier le rôle administrateur
module.exports.isAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Accès non autorisé. Rôle administrateur requis.' });
  }
  next();
};
