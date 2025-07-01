// middleware/auth.js
const { supabase } = require('../config/supabase');

// Middleware d'authentification avec Supabase
const authenticateToken = async (req, res, next) => {
    try {
        console.log('🔐 Middleware d\'authentification appelé');
        console.log('Headers:', req.headers);

        const authHeader = req.headers.authorization;
        console.log('Auth header:', authHeader);

        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
        console.log('Token extrait:', token ? 'Token présent' : 'Token manquant');

        if (!token) {
            console.log('❌ Token manquant');
            return res.status(401).json({ message: 'Token d\'accès requis' });
        }

        // Vérifier le token avec Supabase
        console.log('🔍 Vérification du token avec Supabase...');
        const { data: { user }, error } = await supabase.auth.getUser(token);

        if (error) {
            console.log('❌ Erreur Supabase:', error);
            return res.status(401).json({ message: 'Token invalide' });
        }

        if (!user) {
            console.log('❌ Utilisateur non trouvé');
            return res.status(401).json({ message: 'Token invalide' });
        }

        console.log('✅ Utilisateur authentifié:', user.id);

        // Récupérer le profil utilisateur complet
        console.log('🔍 Récupération du profil utilisateur...');
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        if (profileError) {
            console.log('❌ Erreur profil:', profileError);
            return res.status(401).json({ message: 'Profil utilisateur introuvable' });
        }

        console.log('✅ Profil récupéré:', profile);

        // Ajouter les informations utilisateur à la requête
        req.user = {
            ...profile,
            email: user.email
        };

        console.log('✅ Utilisateur ajouté à req.user:', req.user);
        next();
    } catch (error) {
        console.error('❌ Erreur d\'authentification:', error);
        return res.status(401).json({ message: 'Erreur d\'authentification' });
    }
};

// Middleware pour vérifier si l'utilisateur est admin
const isAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ message: 'Authentification requise' });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Accès refusé - Droits administrateur requis' });
    }

    next();
};

// Middleware pour vérifier si l'utilisateur est vendeur
const isVendor = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ message: 'Authentification requise' });
    }

    if (req.user.role !== 'vendor' && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Accès refusé - Droits vendeur requis' });
    }

    next();
};

// Middleware pour vérifier si l'utilisateur est propriétaire de la ressource
const isOwner = (resourceUserId) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ message: 'Authentification requise' });
        }

        // Les admins peuvent accéder à tout
        if (req.user.role === 'admin') {
            return next();
        }

        // Vérifier si l'utilisateur est propriétaire de la ressource
        if (req.user.id !== resourceUserId) {
            return res.status(403).json({ message: 'Accès refusé - Vous n\'êtes pas propriétaire de cette ressource' });
        }

        next();
    };
};

module.exports = {
    authenticateToken,
    isAdmin,
    isVendor,
    isOwner
};
