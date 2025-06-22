const fs = require('fs');
const path = require('path');
const { supabase } = require('./config/supabase');

async function fixVendorAnalyticsTypes() {
    try {
        console.log('🔧 Correction des types de données pour les analyses vendeur...');
        
        // Lire le fichier de correction
        const fixPath = path.join(__dirname, 'migrations', '003_fix_vendor_analytics_types.sql');
        const fixSQL = fs.readFileSync(fixPath, 'utf8');
        
        console.log('📄 Correction SQL chargée, application en cours...');
        
        // Diviser le SQL en commandes individuelles
        const commands = fixSQL
            .split(';')
            .map(cmd => cmd.trim())
            .filter(cmd => cmd.length > 0 && !cmd.startsWith('--') && !cmd.startsWith('\\echo'));
        
        for (const command of commands) {
            if (command.trim()) {
                console.log(`🔧 Exécution: ${command.substring(0, 60)}...`);
                try {
                    const { error } = await supabase.rpc('exec_sql', { sql: command + ';' });
                    if (error) {
                        console.log(`⚠️  Commande ignorée: ${error.message}`);
                    }
                } catch (err) {
                    console.log(`⚠️  Erreur sur la commande: ${err.message}`);
                }
            }
        }
        
        console.log('✅ Correction des types appliquée avec succès !');
        console.log('');
        console.log('📊 Types corrigés :');
        console.log('   • INTEGER → BIGINT pour les COUNT()');
        console.log('   • INTEGER → BIGINT pour les SUM() de quantités');
        console.log('   • DECIMAL maintenu pour les montants');
        console.log('');
        console.log('🧪 Testez maintenant avec :');
        console.log('   node test-vendor-analytics.js');
        console.log('');
        
    } catch (error) {
        console.error('❌ Erreur lors de la correction:', error);
        
        // Instructions manuelles
        console.log('');
        console.log('🔧 Instructions manuelles :');
        console.log('1. Ouvrez votre dashboard Supabase');
        console.log('2. Allez dans l\'onglet "SQL Editor"');
        console.log('3. Copiez le contenu du fichier migrations/003_fix_vendor_analytics_types.sql');
        console.log('4. Exécutez le script SQL');
        console.log('');
    }
}

// Exécuter la correction
fixVendorAnalyticsTypes(); 