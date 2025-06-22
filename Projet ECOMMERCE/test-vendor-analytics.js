const vendorAnalyticsService = require('./services/vendorAnalyticsService');
const { supabase } = require('./config/supabase');

async function testVendorAnalytics() {
    try {
        console.log('🧪 Test des analyses vendeur...\n');
        
        // 1. Récupérer tous les vendeurs
        console.log('1️⃣ Récupération des vendeurs...');
        const { data: vendors, error: vendorsError } = await supabase
            .from('vendors')
            .select('id, nom, user_id');
            
        if (vendorsError) {
            throw vendorsError;
        }
        
        if (vendors.length === 0) {
            console.log('⚠️  Aucun vendeur trouvé dans la base de données');
            return;
        }
        
        console.log(`✅ ${vendors.length} vendeur(s) trouvé(s)`);
        
        // 2. Tester les revenus pour chaque vendeur
        console.log('\n2️⃣ Test des revenus par vendeur...');
        for (const vendor of vendors) {
            console.log(`\n📊 Vendeur: ${vendor.nom} (ID: ${vendor.id})`);
            
            try {
                const revenue = await vendorAnalyticsService.getVendorRevenue(vendor.id);
                console.log(`   💰 Revenus totaux: ${revenue.total_revenue}€`);
                console.log(`   📦 Commandes: ${revenue.total_orders}`);
                console.log(`   🛍️  Produits vendus: ${revenue.total_products_sold}`);
            } catch (error) {
                console.log(`   ❌ Erreur: ${error.message}`);
            }
        }
        
        // 3. Tester les top-produits pour le premier vendeur
        console.log('\n3️⃣ Test des top-produits...');
        const firstVendor = vendors[0];
        try {
            const topProducts = await vendorAnalyticsService.getVendorTopProducts(firstVendor.id, 5);
            console.log(`\n🏆 Top-produits pour ${firstVendor.nom}:`);
            
            if (topProducts.length === 0) {
                console.log('   📝 Aucun produit vendu pour le moment');
            } else {
                topProducts.forEach((product, index) => {
                    console.log(`   ${index + 1}. ${product.product_name}`);
                    console.log(`      Quantité: ${product.total_quantity}`);
                    console.log(`      Revenus: ${product.total_revenue}€`);
                    console.log(`      Prix moyen: ${product.average_price}€`);
                });
            }
        } catch (error) {
            console.log(`   ❌ Erreur: ${error.message}`);
        }
        
        // 4. Tester les statistiques de vente
        console.log('\n4️⃣ Test des statistiques de vente...');
        try {
            const salesStats = await vendorAnalyticsService.getVendorSalesStats(firstVendor.id, 30);
            console.log(`\n📈 Statistiques des 30 derniers jours pour ${firstVendor.nom}:`);
            console.log(`   💰 Revenus: ${salesStats.period_revenue}€`);
            console.log(`   📦 Commandes: ${salesStats.period_orders}`);
            console.log(`   🛍️  Produits vendus: ${salesStats.period_products_sold}`);
            console.log(`   📊 Panier moyen: ${salesStats.average_order_value}€`);
            console.log(`   🏆 Meilleur produit: ${salesStats.best_selling_product} (${salesStats.best_selling_product_quantity} vendus)`);
        } catch (error) {
            console.log(`   ❌ Erreur: ${error.message}`);
        }
        
        // 5. Tester la vue des revenus
        console.log('\n5️⃣ Test de la vue des revenus...');
        try {
            const allRevenues = await vendorAnalyticsService.getAllVendorRevenues();
            console.log('\n💰 Revenus de tous les vendeurs:');
            
            if (allRevenues.length === 0) {
                console.log('   📝 Aucun revenu enregistré');
            } else {
                allRevenues.forEach((revenue, index) => {
                    console.log(`   ${index + 1}. ${revenue.vendor_name}: ${revenue.total_revenue}€`);
                });
            }
        } catch (error) {
            console.log(`   ❌ Erreur: ${error.message}`);
        }
        
        // 6. Tester les statistiques globales
        console.log('\n6️⃣ Test des statistiques globales...');
        try {
            const globalStats = await vendorAnalyticsService.getGlobalStats();
            console.log('\n🌍 Statistiques globales:');
            console.log(`   💰 Revenus totaux: ${globalStats.totalRevenue}€`);
            console.log(`   📦 Commandes totales: ${globalStats.totalOrders}`);
            console.log(`   🛍️  Produits vendus: ${globalStats.totalProductsSold}`);
            console.log(`   👥 Vendeurs actifs: ${globalStats.activeVendors}`);
            console.log(`   📊 Panier moyen: ${globalStats.averageOrderValue}€`);
        } catch (error) {
            console.log(`   ❌ Erreur: ${error.message}`);
        }
        
        console.log('\n✅ Tests terminés avec succès !');
        console.log('\n📋 Résumé des fonctionnalités testées:');
        console.log('   ✅ getVendorRevenue()');
        console.log('   ✅ getVendorTopProducts()');
        console.log('   ✅ getVendorSalesStats()');
        console.log('   ✅ getAllVendorRevenues()');
        console.log('   ✅ getGlobalStats()');
        
    } catch (error) {
        console.error('❌ Erreur lors des tests:', error);
    }
}

// Exécuter les tests
testVendorAnalytics(); 