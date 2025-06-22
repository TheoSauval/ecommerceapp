// controllers/userController.js
const userService = require('../services/userService');

/**
 * GET /api/users/me
 */
const getProfile = async (req, res) => {
  try {
    // req.user.id est fourni par le middleware d'authentification après vérification du token
    const userId = req.user.id;
    if (!userId) {
      return res.status(401).json({ error: 'Token invalide ou manquant.' });
    }

    const userProfile = await userService.getProfileById(userId);
    if (!userProfile) {
      return res.status(404).json({ error: 'Profil utilisateur non trouvé.' });
    }

    res.json(userProfile);
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: err.message });
  }
};

/**
 * PUT /api/users/me
 */
const updateProfile = async (req, res) => {
  try {
    const { nom, prenom, age } = req.body;
    const user = await userService.updateProfile(req.user.id, { nom, prenom, age });
    res.json({ message: 'Profil mis à jour', user });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: err.message });
  }
};

/**
 * DELETE /api/users/me
 */
const deleteProfile = async (req, res) => {
  try {
    await userService.deleteProfile(req.user.id);

    // Note: L'utilisateur dans auth.users peut rester (selon les permissions)
    // mais toutes ses données (profil, panier, favoris, etc.) sont supprimées
    res.json({
      message: 'Compte supprimé avec succès',
      note: 'Toutes vos données (profil, panier, favoris, commandes) ont été supprimées. Vous devrez vous réinscrire si vous souhaitez utiliser l\'application à nouveau.'
    });
  } catch (err) {
    console.error('Delete profile error:', err);
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  deleteProfile
};
