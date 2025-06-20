// Configuration Supabase - Plus besoin de Sequelize
const { supabase } = require('./supabase');

// Test de connexion Supabase
const testConnection = async () => {
    try {
        const { data, error } = await supabase
            .from('users')
            .select('count', { count: 'exact', head: true });
        
        if (error) {
            console.error('❌ Erreur de connexion Supabase:', error);
        } else {
            console.log('✅ Connexion Supabase établie');
        }
    } catch (err) {
        console.error('❌ Erreur de connexion Supabase:', err);
    }
};

testConnection();

module.exports = { supabase };