// controllers/authController.js
require('dotenv').config();
const authService = require('../services/authService');

/**
 * POST /api/auth/register
 */
const register = async (req, res) => {
  try {
    const { nom, prenom, age, mail, password, role } = req.body;
    
    // Validation des données
    if (!nom || !prenom || !age || !mail || !password) {
      return res.status(400).json({ message: 'Tous les champs sont requis' });
    }
    
    if (age < 0) {
      return res.status(400).json({ message: 'L\'âge doit être positif' });
    }
    
    if (role && !['user', 'vendor', 'admin'].includes(role)) {
      return res.status(400).json({ message: 'Rôle invalide' });
    }
    
    // Créer l'utilisateur
    const user = await authService.register({
      nom,
      prenom,
      age,
      mail,
      password,
      role: role || 'user'
    });
    
    res.status(201).json({
      message: 'Utilisateur créé avec succès',
      user: {
        id: user.id,
        nom: user.nom,
        prenom: user.prenom,
        mail: user.mail,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'inscription:', error);
    res.status(400).json({ message: error.message });
  }
};

/**
 * POST /api/auth/login
 */
const login = async (req, res) => {
  try {
    const { mail, password } = req.body;
    
    // Validation des données
    if (!mail || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }
    
    // Connexion
    const result = await authService.login(mail, password);
    
    res.json({
      message: 'Connexion réussie',
      user: result.user,
      session: {
        access_token: result.session.access_token,
        refresh_token: result.session.refresh_token,
        expires_at: result.session.expires_at
      }
    });
  } catch (error) {
    console.error('Erreur lors de la connexion:', error);
    res.status(401).json({ message: error.message });
  }
};

/**
 * POST /api/auth/logout
 */
const logout = async (req, res) => {
  try {
    await authService.logout();
    res.json({ message: 'Déconnexion réussie' });
  } catch (error) {
    console.error('Erreur lors de la déconnexion:', error);
    res.status(500).json({ message: 'Erreur lors de la déconnexion' });
  }
};

/**
 * POST /api/auth/refresh
 * Body: { refresh_token }
 */
const refreshSession = async (req, res) => {
  try {
    const { refresh_token } = req.body;
    
    if (!refresh_token) {
      return res.status(400).json({ message: 'Refresh token requis' });
    }
    
    const result = await authService.refreshSession(refresh_token);
    
    res.json({
      message: 'Session rafraîchie',
      session: {
        access_token: result.session.access_token,
        refresh_token: result.session.refresh_token,
        expires_at: result.session.expires_at
      }
    });
  } catch (error) {
    console.error('Erreur lors du rafraîchissement:', error);
    res.status(401).json({ message: error.message });
  }
};

/**
 * POST /api/auth/reset
 * Body: { mail }
 */
const requestPasswordReset = async (req, res) => {
  try {
    const { mail } = req.body;
    
    if (!mail) {
      return res.status(400).json({ message: 'Email requis' });
    }
    
    await authService.requestPasswordReset(mail);
    res.json({ message: 'Si cet email existe, un lien a été envoyé' });
  } catch (error) {
    console.error('Erreur lors de la demande de reset:', error);
    res.status(500).json({ message: 'Erreur lors de l\'envoi du lien' });
  }
};

/**
 * PUT /api/auth/reset/:token
 * Body: { newPassword }
 */
const resetPassword = async (req, res) => {
  try {
    const { newPassword } = req.body;
    
    if (!newPassword) {
      return res.status(400).json({ message: 'Nouveau mot de passe requis' });
    }
    
    await authService.resetPassword(newPassword);
    res.json({ message: 'Mot de passe mis à jour avec succès' });
  } catch (error) {
    console.error('Erreur lors du reset:', error);
    res.status(500).json({ message: 'Erreur lors de la mise à jour du mot de passe' });
  }
};

/**
 * GET /api/auth/profile
 */
const getProfile = async (req, res) => {
  try {
    const user = await authService.getCurrentUser();
    res.json({
      user: {
        id: user.id,
        nom: user.nom,
        prenom: user.prenom,
        age: user.age,
        role: user.role,
        email: user.auth_users?.email
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(401).json({ message: error.message });
  }
};

/**
 * PUT /api/auth/profile
 * Body: { nom, prenom, age }
 */
const updateProfile = async (req, res) => {
  try {
    const { nom, prenom, age } = req.body;
    const userId = req.user.id;
    
    // Validation des données
    if (age !== undefined && age < 0) {
      return res.status(400).json({ message: 'L\'âge doit être positif' });
    }
    
    const updates = {};
    if (nom) updates.nom = nom;
    if (prenom) updates.prenom = prenom;
    if (age !== undefined) updates.age = age;
    
    const updatedProfile = await authService.updateProfile(userId, updates);
    
    res.json({
      message: 'Profil mis à jour avec succès',
      user: {
        id: updatedProfile.id,
        nom: updatedProfile.nom,
        prenom: updatedProfile.prenom,
        age: updatedProfile.age,
        role: updatedProfile.role
      }
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du profil:', error);
    res.status(500).json({ message: 'Erreur lors de la mise à jour du profil' });
  }
};

module.exports = {
  register,
  login,
  logout,
  refreshSession,
  requestPasswordReset,
  resetPassword,
  getProfile,
  updateProfile
};
