// controllers/userController.js
const User = require('../models/users');

/**
 * GET /api/users/me
 */
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] }
    });
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }
    res.json(user);
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: err.message });
  }
};

/**
 * PUT /api/users/me
 */
exports.updateProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }
    // On n’autorise ici que ces champs
    const { nom, prenom, age, mail } = req.body;
    await user.update({ nom, prenom, age, mail });
    res.json({ message: 'Profil mis à jour' });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: err.message });
  }
};

/**
 * DELETE /api/users/me
 */
exports.deleteProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }
    // Pour soft-delete, faites user.update({ archived: true }); sinon :
    await user.destroy();
    res.json({ message: 'Compte supprimé' });
  } catch (err) {
    console.error('Delete profile error:', err);
    res.status(500).json({ error: err.message });
  }
};
