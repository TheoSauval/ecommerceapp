const { supabase } = require('../config/supabase');

class UserService {
    // Récupérer le profil d'un utilisateur (sans mot de passe)
    async getProfile(userId) {
        const { data, error } = await supabase
            .from('users')
            .select('id, nom, prenom, age, mail, role, created_at, updated_at')
            .eq('id', userId)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Mettre à jour le profil d'un utilisateur
    async updateProfile(userId, updates) {
        // On n'autorise que certains champs
        const allowedFields = ['nom', 'prenom', 'age', 'mail'];
        const filteredUpdates = {};
        
        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                filteredUpdates[field] = updates[field];
            }
        }
        
        const { data, error } = await supabase
            .from('users')
            .update(filteredUpdates)
            .eq('id', userId)
            .select('id, nom, prenom, age, mail, role, created_at, updated_at')
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Supprimer le profil d'un utilisateur
    async deleteProfile(userId) {
        const { error } = await supabase
            .from('users')
            .delete()
            .eq('id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Récupérer un utilisateur par ID (avec mot de passe)
    async getUserById(id) {
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', id)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer un utilisateur par email
    async getUserByEmail(mail) {
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('mail', mail)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer tous les utilisateurs (admin)
    async getAllUsers() {
        const { data, error } = await supabase
            .from('users')
            .select('id, nom, prenom, age, mail, role, created_at, updated_at')
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        return data;
    }
    
    // Mettre à jour le mot de passe d'un utilisateur
    async updatePassword(userId, newPassword) {
        const bcrypt = require('bcrypt');
        const hash = await bcrypt.hash(newPassword, 10);
        
        const { error } = await supabase
            .from('users')
            .update({ password: hash })
            .eq('id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Récupérer le profil vendeur d'un utilisateur
    async getVendorProfile(userId) {
        const { data, error } = await supabase
            .from('vendors')
            .select('*')
            .eq('user_id', userId)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Créer un profil vendeur
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
    
    // Mettre à jour un profil vendeur
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