// controllers/userController.js
const userService = require('../services/userService');

/**
 * GET /api/users/me
 */
const getProfile = async (req, res) => {
  // Les informations de l'utilisateur (y compris le profil) sont déjà chargées par le middleware d'authentification
  // et stockées dans req.user.
  // Le modèle Swift UserProfile attend 'mail' mais le middleware fournit 'email'.
  const { email, ...profile } = req.user;
  res.json({ ...profile, mail: email });
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
