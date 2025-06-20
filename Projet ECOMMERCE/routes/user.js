// routes/users.js
const express = require('express');
const router  = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getProfile,
  updateProfile,
  deleteProfile
} = require('../controllers/userController');

// GET    /api/users/me    → Récupérer le profil
router.get('/me', authenticateToken, getProfile);

// PUT    /api/users/me    → Mettre à jour le profil
router.put('/me', authenticateToken, updateProfile);

// DELETE /api/users/me    → Supprimer/archiver le compte
router.delete('/me', authenticateToken, deleteProfile);

module.exports = router;
