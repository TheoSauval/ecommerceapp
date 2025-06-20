const { supabase } = require('../config/supabase');

class NotificationService {
    // Récupérer les notifications d'un utilisateur
    async getNotifications(userId) {
        const { data, error } = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false });
            
        if (error) throw error;
        return data;
    }
    
    // Créer une nouvelle notification
    async createNotification(userId, status) {
        const { data, error } = await supabase
            .from('notifications')
            .insert([{
                user_id: userId,
                status
            }])
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Mettre à jour une notification
    async updateNotification(notificationId, updates) {
        const { data, error } = await supabase
            .from('notifications')
            .update(updates)
            .eq('id', notificationId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Supprimer une notification
    async deleteNotification(notificationId, userId) {
        const { error } = await supabase
            .from('notifications')
            .delete()
            .eq('id', notificationId)
            .eq('user_id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Marquer une notification comme lue
    async markAsRead(notificationId, userId) {
        const { data, error } = await supabase
            .from('notifications')
            .update({ status: 'read' })
            .eq('id', notificationId)
            .eq('user_id', userId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Marquer toutes les notifications comme lues
    async markAllAsRead(userId) {
        const { error } = await supabase
            .from('notifications')
            .update({ status: 'read' })
            .eq('user_id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Compter les notifications non lues
    async getUnreadCount(userId) {
        const { count, error } = await supabase
            .from('notifications')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .neq('status', 'read');
            
        if (error) throw error;
        return count || 0;
    }
    
    // Supprimer toutes les notifications d'un utilisateur
    async clearAllNotifications(userId) {
        const { error } = await supabase
            .from('notifications')
            .delete()
            .eq('user_id', userId);
            
        if (error) throw error;
        return true;
    }
    
    // Créer une notification de commande
    async createOrderNotification(userId, orderId, status) {
        const message = `Votre commande #${orderId} a été ${status}`;
        return await this.createNotification(userId, message);
    }
    
    // Créer une notification de produit en rupture
    async createOutOfStockNotification(userId, productName) {
        const message = `Le produit "${productName}" est en rupture de stock`;
        return await this.createNotification(userId, message);
    }
    
    // Créer une notification de promotion
    async createPromotionNotification(userId, promotionText) {
        return await this.createNotification(userId, promotionText);
    }
}

module.exports = new NotificationService(); 