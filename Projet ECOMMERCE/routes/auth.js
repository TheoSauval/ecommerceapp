// routes/auth.js
const express = require('express');
const router = express.Router();
const {
  register,
  login,
  logout,
  refreshSession,
  requestPasswordReset,
  resetPassword,
  getProfile,
  updateProfile
} = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');

// création de compte
router.post('/register', register);

// connexion → renvoie { user, session }
router.post('/login', login);

// déconnexion
router.post('/logout', logout);

// rafraîchir la session en envoyant { refresh_token }
router.post('/refresh', refreshSession);

// demande de lien de réinitialisation { mail }
router.post('/reset', requestPasswordReset);

// reset du mot de passe { newPassword }
router.put('/reset', resetPassword);

// récupérer le profil utilisateur (authentifié)
router.get('/profile', authenticateToken, getProfile);

// mettre à jour le profil utilisateur (authentifié)
router.put('/profile', authenticateToken, updateProfile);

module.exports = router;
