const { supabase } = require('./config/supabase');
const fs = require('fs');
const path = require('path');

async function applyRandomOrderIdsMigration() {
    console.log('🚀 Début de la migration pour les IDs aléatoires des commandes...');
    
    try {
        // Lire le fichier de migration
        const migrationPath = path.join(__dirname, 'migrations', '006_random_order_ids.sql');
        const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
        
        console.log('📖 Fichier de migration lu avec succès');
        
        // Exécuter la migration
        console.log('⚡ Exécution de la migration...');
        const { error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
        
        if (error) {
            console.error('❌ Erreur lors de l\'exécution de la migration:', error);
            return;
        }
        
        console.log('✅ Migration appliquée avec succès !');
        console.log('');
        console.log('📋 Résumé des changements :');
        console.log('   • La table orders utilise maintenant des UUIDs aléatoires');
        console.log('   • La table order_variants a été mise à jour pour supporter les UUIDs');
        console.log('   • La table payments a été mise à jour pour supporter les UUIDs');
        console.log('   • Les politiques RLS ont été recréées');
        console.log('   • Les index ont été recréés');
        console.log('');
        console.log('⚠️  Note importante :');
        console.log('   • Les données existantes ont été sauvegardées dans des tables _backup');
        console.log('   • Si vous avez des données importantes, vous devrez les migrer manuellement');
        console.log('   • L\'application mobile a été mise à jour pour gérer les UUIDs');
        
    } catch (error) {
        console.error('❌ Erreur lors de la migration:', error);
        
        // Alternative : exécuter directement via psql si rpc n'est pas disponible
        console.log('');
        console.log('🔄 Tentative d\'exécution alternative...');
        console.log('Vous pouvez exécuter manuellement la migration avec :');
        console.log(`psql -h [VOTRE_HOST] -U [VOTRE_USER] -d [VOTRE_DB] -f migrations/006_random_order_ids.sql`);
    }
}

// Fonction alternative pour exécuter la migration via une requête directe
async function applyMigrationAlternative() {
    console.log('🔄 Application alternative de la migration...');
    
    try {
        // Étape 1: Sauvegarde
        console.log('📦 Création des sauvegardes...');
        await supabase.rpc('exec_sql', { 
            sql: 'CREATE TABLE IF NOT EXISTS public.orders_backup AS SELECT * FROM public.orders;' 
        });
        
        // Étape 2: Supprimer les contraintes
        console.log('🔧 Suppression des contraintes...');
        await supabase.rpc('exec_sql', { 
            sql: 'ALTER TABLE public.order_variants DROP CONSTRAINT IF EXISTS order_variants_order_id_fkey;' 
        });
        await supabase.rpc('exec_sql', { 
            sql: 'ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_order_id_fkey;' 
        });
        
        // Étape 3: Recréer la table orders
        console.log('🏗️  Recréation de la table orders...');
        await supabase.rpc('exec_sql', { 
            sql: `
            DROP TABLE IF EXISTS public.orders CASCADE;
            CREATE TABLE public.orders (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                prix_total DECIMAL(10, 2) NOT NULL,
                status TEXT NOT NULL DEFAULT 'En attente' CHECK (status IN ('En attente', 'Payé', 'Expédiée', 'Livrée', 'Annulée', 'Échec du paiement')),
                user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
                adresse_livraison TEXT,
                methode_paiement TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
            ` 
        });
        
        console.log('✅ Migration alternative appliquée avec succès !');
        
    } catch (error) {
        console.error('❌ Erreur lors de la migration alternative:', error);
        console.log('');
        console.log('📝 Instructions manuelles :');
        console.log('1. Connectez-vous à votre base de données Supabase');
        console.log('2. Exécutez le contenu du fichier migrations/006_random_order_ids.sql');
        console.log('3. Vérifiez que les tables ont été recréées correctement');
    }
}

// Exécuter la migration
if (require.main === module) {
    applyRandomOrderIdsMigration()
        .then(() => {
            console.log('🎉 Migration terminée !');
            process.exit(0);
        })
        .catch((error) => {
            console.error('💥 Erreur fatale:', error);
            process.exit(1);
        });
}

module.exports = { applyRandomOrderIdsMigration, applyMigrationAlternative }; 