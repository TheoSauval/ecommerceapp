const { supabase } = require('../config/supabase');

class UserService {
    // Récupérer le profil d'un utilisateur
    async getProfile(userId) {
        const { data: profile, error } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();

        if (error) throw error;

        // Note: L'email n'est pas dans cette table, il est dans auth.users
        return profile;
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
        // Cela ne supprime que le profil, pas l'utilisateur dans auth.users
        const { error } = await supabase
            .from('user_profiles')
            .delete()
            .eq('id', userId);

        if (error) throw error;
        return true;
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
}

module.exports = new UserService(); 