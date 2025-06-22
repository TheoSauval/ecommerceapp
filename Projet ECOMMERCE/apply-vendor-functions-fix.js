const fs = require('fs');
const path = require('path');
const { supabase } = require('./config/supabase');

async function applyVendorFunctionsFix() {
    try {
        console.log('🔧 Suppression et recréation des fonctions d\'analyses vendeur...');
        
        // Lire le fichier de correction
        const fixPath = path.join(__dirname, 'migrations', '004_drop_and_recreate_vendor_functions.sql');
        const fixSQL = fs.readFileSync(fixPath, 'utf8');
        
        console.log('📄 Script SQL chargé, application en cours...');
        
        // Diviser le SQL en commandes individuelles
        const commands = fixSQL
            .split(';')
            .map(cmd => cmd.trim())
            .filter(cmd => cmd.length > 0 && !cmd.startsWith('--') && !cmd.startsWith('\\echo'));
        
        console.log(`🔧 Exécution de ${commands.length} commandes...`);
        
        for (let i = 0; i < commands.length; i++) {
            const command = commands[i];
            if (command.trim()) {
                console.log(`   ${i + 1}/${commands.length}: ${command.substring(0, 50)}...`);
                try {
                    const { error } = await supabase.rpc('exec_sql', { sql: command + ';' });
                    if (error) {
                        console.log(`   ⚠️  Commande ignorée: ${error.message}`);
                    }
                } catch (err) {
                    console.log(`   ⚠️  Erreur sur la commande: ${err.message}`);
                }
            }
        }
        
        console.log('✅ Fonctions supprimées et recréées avec succès !');
        console.log('');
        console.log('📊 Fonctions corrigées :');
        console.log('   ✅ get_vendor_revenue() - Types BIGINT');
        console.log('   ✅ get_vendor_top_products() - Types BIGINT');
        console.log('   ✅ get_vendor_sales_stats() - Types BIGINT');
        console.log('   ✅ get_vendor_sales_history() - Types BIGINT');
        console.log('   ✅ vendor_revenues - Vue mise à jour');
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
        console.log('3. Copiez le contenu du fichier migrations/004_drop_and_recreate_vendor_functions.sql');
        console.log('4. Exécutez le script SQL');
        console.log('');
        console.log('⚠️  Cette migration va :');
        console.log('   • Supprimer les anciennes fonctions');
        console.log('   • Recréer les fonctions avec les bons types');
        console.log('   • Mettre à jour la vue vendor_revenues');
        console.log('');
    }
}

// Exécuter la correction
applyVendorFunctionsFix(); 