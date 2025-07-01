const { supabase, createMobileClient, createDashboardClient } = require('../config/supabase');

class AuthService {
    // Inscription d'un utilisateur avec Supabase Auth
    async register(userData) {
        const { nom, prenom, age, mail, password, role } = userData;

        // Créer l'utilisateur avec Supabase Auth
        const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            email: mail,
            password: password,
            email_confirm: true, // Auto-confirmer l'email pour les tests
            user_metadata: {
                nom,
                prenom,
                age,
                role: role || 'user'
            }
        });

        if (authError) {
            if (authError.message.includes('already registered')) {
                throw new Error('Cet email est déjà utilisé');
            }
            throw new Error(authError.message);
        }

        // Le profil est créé automatiquement par un trigger.
        // On attend un peu pour éviter les race conditions.
        let profile = null;
        for (let i = 0; i < 5; i++) {
            const { data } = await supabase
                .from('user_profiles')
                .select('*')
                .eq('id', authUser.user.id)
                .single();

            if (data) {
                profile = data;
                break;
            }
            // Attendre 300ms avant de réessayer
            await new Promise(resolve => setTimeout(resolve, 300));
        }

        if (!profile) {
            // Si le profil n'est toujours pas trouvé, on supprime l'utilisateur pour la cohérence
            await supabase.auth.admin.deleteUser(authUser.user.id);
            throw new Error("La création du profil utilisateur a échoué après l'authentification.");
        }

        // Si c'est un vendeur, créer le profil vendeur
        if (role === 'vendor') {
            await supabase
                .from('vendors')
                .insert([{
                    nom: `${prenom} ${nom}`,
                    user_id: authUser.user.id
                }]);
        }

        return {
            id: authUser.user.id,
            mail: authUser.user.email,
            nom: profile.nom,
            prenom: profile.prenom,
            role: profile.role
        };
    }

    // Connexion d'un utilisateur avec Supabase Auth (version mobile)
    async loginMobile(mail, password) {
        // Utiliser un client séparé pour l'app mobile
        const mobileClient = createMobileClient();
        
        // Connexion avec Supabase Auth
        const { data: authData, error: authError } = await mobileClient.auth.signInWithPassword({
            email: mail,
            password: password
        });

        if (authError) {
            throw new Error('Identifiants invalides');
        }

        // Récupérer le profil utilisateur
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', authData.user.id)
            .single();

        if (profileError) throw profileError;

        return {
            user: {
                id: authData.user.id,
                email: authData.user.email,
                nom: profile.nom,
                prenom: profile.prenom,
                role: profile.role
            },
            session: {
                access_token: authData.session.access_token,
                refresh_token: authData.session.refresh_token,
                expires_at: authData.session.expires_at
            }
        };
    }

    // Connexion d'un utilisateur avec Supabase Auth (version dashboard)
    async loginDashboard(mail, password) {
        // Utiliser un client séparé pour le dashboard
        const dashboardClient = createDashboardClient();
        
        // Connexion avec Supabase Auth
        const { data: authData, error: authError } = await dashboardClient.auth.signInWithPassword({
            email: mail,
            password: password
        });

        if (authError) {
            throw new Error('Identifiants invalides');
        }

        // Récupérer le profil utilisateur
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', authData.user.id)
            .single();

        if (profileError) throw profileError;

        return {
            user: {
                id: authData.user.id,
                email: authData.user.email,
                nom: profile.nom,
                prenom: profile.prenom,
                role: profile.role
            },
            session: {
                access_token: authData.session.access_token,
                refresh_token: authData.session.refresh_token,
                expires_at: authData.session.expires_at
            }
        };
    }

    // Connexion générique (pour compatibilité)
    async login(mail, password) {
        // Par défaut, utiliser la version mobile
        return this.loginMobile(mail, password);
    }

    // Rafraîchir la session
    async refreshSession(refreshToken) {
        // Utiliser le client générique pour le rafraîchissement
        const { createClient } = require('@supabase/supabase-js');
        const tempClient = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_ANON_KEY,
            {
                auth: {
                    autoRefreshToken: true,
                    persistSession: false,
                    detectSessionInUrl: false
                }
            }
        );

        const { data, error } = await tempClient.auth.refreshSession({
            refresh_token: refreshToken
        });

        if (error) {
            throw new Error('Session invalide');
        }

        return data;
    }

    // Déconnexion
    async logout(token = null) {
        if (token) {
            // Déconnecter une session spécifique
            const { error } = await supabase.auth.admin.signOut(token);
            if (error) throw error;
        } else {
            // Déconnexion générale (pour compatibilité)
            const { createClient } = require('@supabase/supabase-js');
            const tempClient = createClient(
                process.env.SUPABASE_URL,
                process.env.SUPABASE_ANON_KEY
            );
            const { error } = await tempClient.auth.signOut();
            if (error) throw error;
        }
        return { message: 'Déconnexion réussie' };
    }

    // Demande de réinitialisation de mot de passe
    async requestPasswordReset(mail) {
        const { error } = await supabasePublic.auth.resetPasswordForEmail(mail, {
            redirectTo: `${process.env.FRONTEND_URL}/reset-password`
        });

        if (error) throw error;

        return { message: 'Si cet email existe, un lien a été envoyé' };
    }

    // Réinitialisation du mot de passe
    async resetPassword(newPassword) {
        const { error } = await supabasePublic.auth.updateUser({
            password: newPassword
        });

        if (error) throw error;

        return { message: 'Mot de passe mis à jour' };
    }

    // Changer le mot de passe (nécessite l'ancien mot de passe)
    async changePassword(oldPassword, newPassword) {
        // D'abord, vérifier que l'ancien mot de passe est correct
        const { data: { user }, error: getUserError } = await supabasePublic.auth.getUser();
        
        if (getUserError || !user) {
            throw new Error('Utilisateur non authentifié');
        }

        // Vérifier l'ancien mot de passe en tentant une connexion
        const { error: verifyError } = await supabasePublic.auth.signInWithPassword({
            email: user.email,
            password: oldPassword
        });

        if (verifyError) {
            throw new Error('Ancien mot de passe incorrect');
        }

        // Maintenant changer le mot de passe
        const { error: updateError } = await supabasePublic.auth.updateUser({
            password: newPassword
        });

        if (updateError) {
            throw new Error('Erreur lors du changement de mot de passe');
        }

        return { message: 'Mot de passe changé avec succès' };
    }

    // Récupérer un utilisateur par ID
    async getUserById(id) {
        const { data, error } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', id)
            .single();

        if (error) throw error;

        // Récupérer l'email depuis auth.users si nécessaire
        const { data: authUser } = await supabase.auth.admin.getUserById(id);

        return {
            ...data,
            email: authUser?.user?.email
        };
    }

    // Récupérer un utilisateur par email
    async getUserByEmail(mail) {
        const { data: authUser, error: authError } = await supabase.auth.admin.getUserByEmail(mail);

        if (authError || !authUser.user) {
            throw new Error('Utilisateur non trouvé');
        }

        return await this.getUserById(authUser.user.id);
    }

    // Mettre à jour le profil utilisateur
    async updateProfile(userId, updates) {
        const { data, error } = await supabase
            .from('user_profiles')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Vérifier si un utilisateur est authentifié
    async getCurrentUser() {
        const { data: { user }, error } = await supabasePublic.auth.getUser();

        if (error || !user) {
            throw new Error('Utilisateur non authentifié');
        }

        return await this.getUserById(user.id);
    }
}

module.exports = new AuthService(); 