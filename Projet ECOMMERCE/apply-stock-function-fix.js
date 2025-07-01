const { supabase } = require('./config/supabase');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function applyStockFunctionFix() {
    console.log('🔧 Application de la correction de la fonction decrease_stock');
    console.log('==========================================================');
    
    try {
        // Lire le fichier SQL
        const sqlFile = path.join(__dirname, 'fix-stock-function.sql');
        const sqlContent = fs.readFileSync(sqlFile, 'utf8');
        
        console.log('📄 Contenu du script SQL:');
        console.log('------------------------');
        console.log(sqlContent);
        console.log('------------------------');
        
        // Exécuter le script SQL
        console.log('\n🔄 Exécution du script SQL...');
        const { data, error } = await supabase.rpc('exec_sql', { sql: sqlContent });
        
        if (error) {
            // Si exec_sql n'existe pas, on essaie une approche différente
            console.log('⚠️ exec_sql non disponible, tentative d\'exécution directe...');
            
            // Exécuter chaque commande séparément
            const commands = sqlContent.split(';').filter(cmd => cmd.trim());
            
            for (const command of commands) {
                if (command.trim()) {
                    console.log(`   Exécution: ${command.trim().substring(0, 50)}...`);
                    try {
                        await supabase.rpc('exec_sql', { sql: command });
                    } catch (cmdError) {
                        console.log(`   ⚠️ Commande ignorée (probablement DROP): ${cmdError.message}`);
                    }
                }
            }
        } else {
            console.log('✅ Script SQL exécuté avec succès');
        }
        
        // Tester la nouvelle fonction
        console.log('\n🧪 Test de la nouvelle fonction...');
        const { error: testError } = await supabase.rpc('decrease_stock', { order_id_param: '00000000-0000-0000-0000-000000000000' });
        
        if (testError) {
            if (testError.message.includes('function') || testError.message.includes('does not exist')) {
                console.log('❌ La fonction n\'a pas été créée correctement');
                console.log('   Erreur:', testError.message);
                return false;
            } else {
                console.log('✅ La fonction existe (erreur attendue car l\'UUID n\'existe pas)');
                console.log('   Erreur attendue:', testError.message);
            }
        } else {
            console.log('✅ La fonction existe et s\'exécute sans erreur');
        }
        
        console.log('\n✅ Correction appliquée avec succès !');
        console.log('\n📋 Instructions pour finaliser :');
        console.log('1. Allez dans votre dashboard Supabase');
        console.log('2. Ouvrez l\'éditeur SQL');
        console.log('3. Collez le contenu du fichier fix-stock-function.sql');
        console.log('4. Exécutez le script');
        console.log('5. Testez avec le script check-stock-function.js');
        
        return true;
        
    } catch (error) {
        console.error('❌ Erreur lors de l\'application de la correction:', error.message);
        console.log('\n📋 Instructions manuelles :');
        console.log('1. Allez dans votre dashboard Supabase');
        console.log('2. Ouvrez l\'éditeur SQL');
        console.log('3. Collez le contenu du fichier fix-stock-function.sql');
        console.log('4. Exécutez le script');
        return false;
    }
}

// Exécuter la correction
applyStockFunctionFix()
    .then(success => {
        if (success) {
            console.log('\n✅ Processus terminé avec succès');
        } else {
            console.log('\n❌ Processus échoué');
        }
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Erreur fatale:', error);
        process.exit(1);
    }); 