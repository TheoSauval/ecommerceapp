// controllers/authController.js
require('dotenv').config();
const bcrypt = require('bcrypt');
const jwt    = require('jsonwebtoken');
const User   = require('../models/users');
const Vendeur = require('../models/vendors');

/**
 * POST /api/auth/register
 */
exports.register = async (req, res) => {
  try {
    const { nom, prenom, age, mail, password, role } = req.body;
    // 1) doublon d'email ?
    if (await User.findOne({ where: { mail } })) {
      return res.status(400).json({ error: 'Cet email est déjà utilisé' });
    }
    // 2) hash
    const hash = await bcrypt.hash(password, 10);
    // 3) création
    const user = await User.create({ 
      nom, 
      prenom, 
      age, 
      mail, 
      password: hash,
      role: role || 'user' // Use provided role or default to 'user'
    });

    // If user is a vendor, create a corresponding vendor record
    if (role === 'vendor') {
      await Vendeur.create({
        nom: `${prenom} ${nom}`,
        user_id: user.id
      });
    }

    return res.status(201).json({
      id:     user.id,
      mail:   user.mail,
      nom:    user.nom,
      prenom: user.prenom,
      role:   user.role
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/**
 * POST /api/auth/login
 */
exports.login = async (req, res) => {
  try {
    const { mail, password } = req.body;
    const user = await User.findOne({ where: { mail } });
    if (!user) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }
    // vérif mdp
    if (!await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }
    const payload = { id: user.id, mail: user.mail, role: user.role };
    // 1) access token court
    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: '15m'
    });
    // 2) refresh token longue durée
    const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
      expiresIn: '7d'
    });
    return res.json({ token, refreshToken });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/**
 * POST /api/auth/refresh
 * Body: { refreshToken }
 */
exports.refreshToken = (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(401).json({ message: 'Refresh token manquant' });
  }
  jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, (err, payload) => {
    if (err) {
      return res.status(401).json({ message: 'Refresh token invalide' });
    }
    // nouveau access token
    const newToken = jwt.sign(
      { id: payload.id, mail: payload.mail },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );
    return res.json({ token: newToken });
  });
};

/**
 * POST /api/auth/reset
 * Body: { mail }
 */
exports.requestPasswordReset = async (req, res) => {
  const { mail } = req.body;
  const user = await User.findOne({ where: { mail } });
  // on ne leak pas l'existance de l'email
  if (user) {
    const payload = { id: user.id, mail: user.mail };
    const resetToken = jwt.sign(payload, process.env.RESET_PASSWORD_SECRET, {
      expiresIn: '1h'
    });
    // → ici envoi mail par nodemailer avec lien incluant ce token
    console.log(`Password reset token for ${mail}: ${resetToken}`);
    // pour les tests, on renvoie aussi le token
    if (process.env.NODE_ENV === 'test') {
      return res.json({
        message: 'Si cet email existe, un lien a été envoyé',
        resetToken
      });
    }
  }
  return res.json({ message: 'Si cet email existe, un lien a été envoyé' });
};

/**
 * PUT /api/auth/reset/:token
 * Body: { password }
 */
exports.resetPassword = (req, res) => {
  const { token } = req.params;
  const { password } = req.body;
  jwt.verify(token, process.env.RESET_PASSWORD_SECRET, async (err, payload) => {
    if (err) {
      return res.status(400).json({ message: 'Token invalide ou expiré' });
    }
    const user = await User.findByPk(payload.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }
    const hash = await bcrypt.hash(password, 10);
    user.password = hash;
    await user.save();
    return res.json({ message: 'Mot de passe mis à jour' });
  });
};
