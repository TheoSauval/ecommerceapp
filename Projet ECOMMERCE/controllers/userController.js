// controllers/userController.js
const userService = require('../services/userService');

/**
 * GET /api/users/me
 */
const getProfile = async (req, res) => {
  try {
    const user = await userService.getProfile(req.user.id);
    res.json(user);
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(404).json({ message: 'Utilisateur introuvable' });
  }
};

/**
 * PUT /api/users/me
 */
const updateProfile = async (req, res) => {
  try {
    const { nom, prenom, age, mail } = req.body;
    const user = await userService.updateProfile(req.user.id, { nom, prenom, age, mail });
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
    res.json({ message: 'Compte supprimé' });
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
