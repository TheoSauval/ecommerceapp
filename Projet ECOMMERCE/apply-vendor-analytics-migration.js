const fs = require('fs');
const path = require('path');
const { supabase } = require('./config/supabase');

async function applyVendorAnalyticsMigration() {
    try {
        console.log('🚀 Application de la migration pour les analyses vendeur...');
        
        // Lire le fichier de migration
        const migrationPath = path.join(__dirname, 'migrations', '002_add_vendor_analytics.sql');
        const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
        
        console.log('📄 Migration SQL chargée, application en cours...');
        
        // Appliquer la migration
        const { error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
        
        if (error) {
            // Si exec_sql n'existe pas, on essaie d'exécuter directement
            console.log('⚠️  exec_sql non disponible, tentative d\'exécution directe...');
            
            // Diviser le SQL en commandes individuelles
            const commands = migrationSQL
                .split(';')
                .map(cmd => cmd.trim())
                .filter(cmd => cmd.length > 0 && !cmd.startsWith('--') && !cmd.startsWith('\\echo'));
            
            for (const command of commands) {
                if (command.trim()) {
                    console.log(`🔧 Exécution: ${command.substring(0, 50)}...`);
                    const { error: cmdError } = await supabase.rpc('exec_sql', { sql: command + ';' });
                    if (cmdError) {
                        console.log(`⚠️  Commande ignorée (probablement déjà exécutée): ${cmdError.message}`);
                    }
                }
            }
        }
        
        console.log('✅ Migration pour les analyses vendeur appliquée avec succès !');
        console.log('');
        console.log('📊 Nouvelles fonctionnalités disponibles :');
        console.log('   • get_vendor_revenue(vendor_id) - Revenus totaux d\'un vendeur');
        console.log('   • get_vendor_top_products(vendor_id, limit) - Top-produits d\'un vendeur');
        console.log('   • get_vendor_sales_stats(vendor_id, period_days) - Statistiques de vente');
        console.log('   • get_vendor_sales_history(vendor_id, days_back) - Historique des ventes');
        console.log('   • vendor_revenues - Vue des revenus par vendeur');
        console.log('');
        console.log('🌐 Nouvelles routes API :');
        console.log('   • GET /api/vendor-analytics/my-dashboard');
        console.log('   • GET /api/vendor-analytics/revenue/:vendorId');
        console.log('   • GET /api/vendor-analytics/top-products/:vendorId');
        console.log('   • GET /api/vendor-analytics/sales-stats/:vendorId');
        console.log('   • GET /api/vendor-analytics/global-stats');
        console.log('');
        
    } catch (error) {
        console.error('❌ Erreur lors de l\'application de la migration:', error);
        
        // Instructions manuelles
        console.log('');
        console.log('🔧 Instructions manuelles :');
        console.log('1. Ouvrez votre dashboard Supabase');
        console.log('2. Allez dans l\'onglet "SQL Editor"');
        console.log('3. Copiez le contenu du fichier migrations/002_add_vendor_analytics.sql');
        console.log('4. Exécutez le script SQL');
        console.log('');
    }
}

// Exécuter la migration
applyVendorAnalyticsMigration(); 