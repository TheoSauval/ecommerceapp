const { supabase } = require('./config/supabase');

async function checkSupabaseSetup() {
    console.log('🔍 Vérification de la configuration Supabase...\n');

    try {
        // 1. Vérifier la connexion
        console.log('1. Test de connexion...');
        const { data: testData, error: testError } = await supabase
            .from('user_profiles')
            .select('count')
            .limit(1);
        
        if (testError) {
            console.error('❌ Erreur de connexion:', testError.message);
            return false;
        }
        console.log('✅ Connexion réussie\n');

        // 2. Vérifier les buckets de stockage
        console.log('2. Vérification des buckets de stockage...');
        const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
        
        if (bucketError) {
            console.error('❌ Erreur lors de la récupération des buckets:', bucketError.message);
            return false;
        }

        const bucketNames = buckets.map(b => b.name);
        console.log('📦 Buckets disponibles:', bucketNames);

        const productImagesBucket = buckets.find(b => b.name === 'product-images');
        if (!productImagesBucket) {
            console.error('❌ Bucket "product-images" non trouvé');
            console.log('💡 Veuillez exécuter le script supabase-storage-setup.sql dans l\'éditeur SQL de Supabase');
            return false;
        }
        console.log('✅ Bucket "product-images" trouvé\n');

        // 3. Vérifier les tables principales
        console.log('3. Vérification des tables principales...');
        const tablesToCheck = [
            'user_profiles',
            'vendors', 
            'products',
            'product_variants',
            'colors',
            'heights'
        ];

        for (const tableName of tablesToCheck) {
            try {
                const { data, error } = await supabase
                    .from(tableName)
                    .select('count')
                    .limit(1);
                
                if (error) {
                    console.error(`❌ Table "${tableName}" non accessible:`, error.message);
                    return false;
                }
                console.log(`✅ Table "${tableName}" accessible`);
            } catch (err) {
                console.error(`❌ Erreur avec la table "${tableName}":`, err.message);
                return false;
            }
        }
        console.log('');

        // 4. Vérifier les données de base
        console.log('4. Vérification des données de base...');
        
        // Vérifier les couleurs
        const { data: colors, error: colorsError } = await supabase
            .from('colors')
            .select('*')
            .limit(5);
        
        if (colorsError) {
            console.error('❌ Erreur lors de la récupération des couleurs:', colorsError.message);
        } else {
            console.log(`✅ ${colors.length} couleurs trouvées`);
        }

        // Vérifier les tailles
        const { data: heights, error: heightsError } = await supabase
            .from('heights')
            .select('*')
            .limit(5);
        
        if (heightsError) {
            console.error('❌ Erreur lors de la récupération des tailles:', heightsError.message);
        } else {
            console.log(`✅ ${heights.length} tailles trouvées`);
        }

        console.log('\n🎉 Configuration Supabase vérifiée avec succès !');
        console.log('\n📋 Prochaines étapes:');
        console.log('1. Assurez-vous que votre serveur backend est démarré');
        console.log('2. Testez l\'ajout d\'un produit avec images');
        console.log('3. Vérifiez que les images s\'affichent correctement');
        
        return true;

    } catch (error) {
        console.error('❌ Erreur lors de la vérification:', error.message);
        return false;
    }
}

// Exécuter la vérification si le script est appelé directement
if (require.main === module) {
    checkSupabaseSetup()
        .then(success => {
            if (!success) {
                console.log('\n🔧 Actions à effectuer:');
                console.log('1. Vérifiez vos variables d\'environnement (.env)');
                console.log('2. Exécutez le script supabase-storage-setup.sql dans Supabase');
                console.log('3. Vérifiez que votre projet Supabase est actif');
                process.exit(1);
            }
        })
        .catch(error => {
            console.error('❌ Erreur fatale:', error);
            process.exit(1);
        });
}

module.exports = { checkSupabaseSetup }; 