// routes/auth.js
const express = require('express');
const router  = express.Router();
const {
  register,
  login,
  refreshToken,
  requestPasswordReset,
  resetPassword
} = require('../controllers/authController');

// création de compte
router.post('/register', register);

// connexion → renvoie { token, refreshToken }
router.post('/login',    login);

// rafraîchir l’access token en envoyant { refreshToken }
router.post('/refresh',  refreshToken);

// demande de lien de réinitialisation { mail }
router.post('/reset',    requestPasswordReset);

// reset du mot de passe via token URL + { password }
router.put('/reset/:token', resetPassword);

module.exports = router;
