const { supabase, supabasePublic } = require('../config/supabase');

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

        // Insérer explicitement dans user_profiles
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .insert({
                id: authUser.user.id,
                nom: nom,
                prenom: prenom,
                age: age,
                role: role || 'user'
            })
            .select()
            .single();

        if (profileError) {
            // En cas d'échec de création du profil, supprimer l'utilisateur Auth pour la cohérence
            await supabase.auth.admin.deleteUser(authUser.user.id);
            throw profileError;
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

    // Connexion d'un utilisateur avec Supabase Auth
    async login(mail, password) {
        // Connexion avec Supabase Auth
        const { data: authData, error: authError } = await supabasePublic.auth.signInWithPassword({
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
            session: authData.session
        };
    }

    // Rafraîchir la session
    async refreshSession(refreshToken) {
        const { data, error } = await supabasePublic.auth.refreshSession({
            refresh_token: refreshToken
        });

        if (error) {
            throw new Error('Session invalide');
        }

        return data;
    }

    // Déconnexion
    async logout() {
        const { error } = await supabasePublic.auth.signOut();
        if (error) throw error;
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