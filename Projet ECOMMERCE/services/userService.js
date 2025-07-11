const { supabase } = require('../config/supabase');

class UserService {
    // Récupérer le profil d'un utilisateur par son ID
    async getProfileById(userId) {
        let { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();

        // Gérer le cas où le profil n'existe pas (par exemple pour un ancien utilisateur)
        if (profileError && profileError.code === 'PGRST116') {
            console.log(`Profil non trouvé pour l'ID ${userId} (PGRST116). Tentative de création à la volée.`);

            // 1. Récupérer les métadonnées depuis auth.users
            const { data: authUser, error: authUserError } = await supabase.auth.admin.getUserById(userId);

            if (authUserError || !authUser.user) {
                console.error("Impossible de récupérer les données d'authentification pour créer le profil manquant:", authUserError);
                throw new Error("Utilisateur d'authentification introuvable pour créer le profil.");
            }

            const { nom, prenom, age, role } = authUser.user.user_metadata || {};

            // 2. Vérifier si on a assez d'infos
            if (!nom || !prenom || age === undefined) {
                console.error("Métadonnées (nom, prenom, age) manquantes dans auth.users pour la création du profil :", authUser.user.user_metadata);
                throw new Error("Données insuffisantes pour créer le profil utilisateur.");
            }

            // 3. Créer le profil dans la base de données
            const { data: newProfile, error: insertError } = await supabase
                .from('user_profiles')
                .insert({
                    id: userId,
                    nom,
                    prenom,
                    age,
                    role: role || 'user'
                })
                .select()
                .single();

            if (insertError) {
                console.error("Erreur lors de l'insertion du nouveau profil :", insertError);
                throw insertError;
            }

            console.log("Profil manquant créé avec succès.");
            profile = newProfile; // On utilise le profil nouvellement créé

        } else if (profileError) {
            // Gérer les autres erreurs possibles de la requête
            console.error("Erreur inattendue lors de la récupération du profil :", profileError);
            throw profileError;
        }

        if (!profile) {
            // Ce cas ne devrait plus arriver, mais par sécurité
            return null;
        }

        // Récupérer l'email depuis auth.users pour l'ajouter à la réponse
        const { data: authData, error: authError } = await supabase.auth.admin.getUserById(userId);
        if (authError) {
            console.error("Impossible de récupérer l'utilisateur Auth pour l'email:", authError.message);
        }

        return {
            ...profile,
            email: authData?.user?.email ?? ''
        };
    }

    // Mettre à jour le profil d'un utilisateur
    async updateProfile(userId, updates) {
        // On n'autorise que certains champs
        const allowedFields = ['nom', 'prenom', 'age'];
        const filteredUpdates = {};

        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                filteredUpdates[field] = updates[field];
            }
        }

        const { data, error } = await supabase
            .from('user_profiles')
            .update(filteredUpdates)
            .eq('id', userId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Supprimer le profil d'un utilisateur
    async deleteProfile(userId) {
        try {
            // Méthode 1: Supprimer l'utilisateur dans auth.users (nécessite permissions admin)
            try {
                const { error } = await supabase.auth.admin.deleteUser(userId);
                if (error) throw error;
                return true;
            } catch (adminError) {
                console.log('Permissions admin non disponibles, suppression manuelle des données...');

                // Méthode 2: Suppression manuelle de toutes les données liées
                // Supprimer dans l'ordre pour éviter les erreurs de contraintes

                // 1. Supprimer les éléments du panier
                const { error: cartError } = await supabase
                    .from('cart_items')
                    .delete()
                    .eq('user_id', userId);
                if (cartError) console.error('Erreur suppression panier:', cartError);

                // 2. Supprimer les favoris
                const { error: favError } = await supabase
                    .from('favorites')
                    .delete()
                    .eq('user_id', userId);
                if (favError) console.error('Erreur suppression favoris:', favError);

                // 3. Supprimer les notifications
                const { error: notifError } = await supabase
                    .from('notifications')
                    .delete()
                    .eq('user_id', userId);
                if (notifError) console.error('Erreur suppression notifications:', notifError);

                // 4. Supprimer les paiements
                const { error: payError } = await supabase
                    .from('payments')
                    .delete()
                    .eq('user_id', userId);
                if (payError) console.error('Erreur suppression paiements:', payError);

                // 5. Supprimer les commandes (et leurs order_variants via CASCADE)
                const { error: orderError } = await supabase
                    .from('orders')
                    .delete()
                    .eq('user_id', userId);
                if (orderError) console.error('Erreur suppression commandes:', orderError);

                // 6. Supprimer le profil vendeur si il existe
                const { error: vendorError } = await supabase
                    .from('vendors')
                    .delete()
                    .eq('user_id', userId);
                if (vendorError) console.error('Erreur suppression vendeur:', vendorError);

                // 7. Enfin, supprimer le profil utilisateur
                const { error: profileError } = await supabase
                    .from('user_profiles')
                    .delete()
                    .eq('id', userId);
                if (profileError) throw profileError;

                console.log('✅ Suppression manuelle des données utilisateur terminée');
                return true;
            }
        } catch (err) {
            console.error('Error deleting user:', err);
            throw err;
        }
    }

    // Récupérer tous les profils (admin)
    async getAllUsers() {
        const { data, error } = await supabase
            .from('user_profiles')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;
        return data;
    }

    // Le reste des fonctions (getUserById, getUserByEmail, updatePassword)
    // interagiraient avec auth.users et nécessiteraient les fonctions d'admin de Supabase,
    // ce qui est plus complexe et sort du cadre de la correction actuelle.
    // Ces fonctions sont laissées telles quelles mais ne fonctionneront pas
    // car la table 'users' n'existe pas.

    // ... fonctions obsolètes ...
    async getUserById(id) {
        // OBSOLETE: interagirait avec auth.users
        return null;
    }

    async getUserByEmail(mail) {
        // OBSOLETE: interagirait avec auth.users
        return null;
    }

    async updatePassword(userId, newPassword) {
        // OBSOLETE: se gère côté client avec les fonctions de Supabase Auth
        return true;
    }

    // ... le reste des fonctions (vendor, etc) ...
    async getVendorProfile(userId) {
        const { data, error } = await supabase
            .from('vendors')
            .select('*')
            .eq('user_id', userId)
            .single();

        if (error) throw error;
        return data;
    }

    async createVendorProfile(userId, vendorData) {
        const { data, error } = await supabase
            .from('vendors')
            .insert([{
                ...vendorData,
                user_id: userId
            }])
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    async updateVendorProfile(vendorId, updates) {
        const { data, error } = await supabase
            .from('vendors')
            .update(updates)
            .eq('id', vendorId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    // Vérifier si un utilisateur existe dans auth.users
    async checkUserExists(userId) {
        try {
            const { data, error } = await supabase.auth.admin.getUserById(userId);
            if (error) {
                if (error.message.includes('User not found')) {
                    return false;
                }
                throw error;
            }
            return !!data.user;
        } catch (err) {
            console.error('Error checking user existence:', err);
            return false;
        }
    }
}

module.exports = new UserService(); 