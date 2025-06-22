# 📊 Analyses Vendeur - Guide Complet

## 🎯 **Problème Résolu**

Votre dashboard admin ne pouvait pas afficher les revenus et top-produits des vendeurs car il manquait des **fonctions SQL spécialisées** pour calculer ces données complexes.

## ✅ **Solution Implémentée**

J'ai créé un système complet d'analyses vendeur avec :

### 🔧 **1. Fonctions SQL Optimisées**
- `get_vendor_revenue(vendor_id)` - Revenus totaux d'un vendeur
- `get_vendor_top_products(vendor_id, limit)` - Top-produits d'un vendeur
- `get_vendor_sales_stats(vendor_id, period_days)` - Statistiques de vente
- `get_vendor_sales_history(vendor_id, days_back)` - Historique des ventes
- `vendor_revenues` - Vue des revenus par vendeur

### 🌐 **2. API REST Complète**
- `GET /api/vendor-analytics/my-dashboard` - Dashboard du vendeur connecté
- `GET /api/vendor-analytics/revenue/:vendorId` - Revenus d'un vendeur
- `GET /api/vendor-analytics/top-products/:vendorId` - Top-produits
- `GET /api/vendor-analytics/sales-stats/:vendorId` - Statistiques
- `GET /api/vendor-analytics/global-stats` - Statistiques globales (admin)

### 📊 **3. Service JavaScript**
- `VendorAnalyticsService` - Service pour gérer toutes les analyses
- `VendorAnalyticsController` - Contrôleur API
- Routes dédiées dans `/routes/vendorAnalytics.js`

## 🚀 **Installation**

### **Étape 1 : Appliquer la Migration SQL**

```bash
# Option 1 : Script automatique
node apply-vendor-analytics-migration.js

# Option 2 : Manuel (dans Supabase Dashboard)
# 1. Ouvrir Supabase Dashboard
# 2. Aller dans "SQL Editor"
# 3. Copier le contenu de migrations/002_add_vendor_analytics.sql
# 4. Exécuter le script
```

### **Étape 2 : Tester les Fonctionnalités**

```bash
# Tester toutes les analyses
node test-vendor-analytics.js
```

### **Étape 3 : Redémarrer le Serveur**

```bash
npm start
# ou
node app.js
```

## 📋 **Utilisation**

### **Pour un Vendeur (Dashboard Personnel)**

```javascript
// Récupérer le dashboard du vendeur connecté
const response = await fetch('/api/vendor-analytics/my-dashboard', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
});

const dashboard = await response.json();
console.log(dashboard.data);
// {
//   revenue: { total_revenue: 1500, total_orders: 25, total_products_sold: 45 },
//   topProducts: [...],
//   salesStats: { period_revenue: 500, period_orders: 8, ... },
//   salesHistory: [...]
// }
```

### **Pour un Admin (Tous les Vendeurs)**

```javascript
// Revenus de tous les vendeurs
const response = await fetch('/api/vendor-analytics/all-revenues');
const revenues = await response.json();

// Statistiques globales
const globalStats = await fetch('/api/vendor-analytics/global-stats');
const stats = await globalStats.json();
```

### **Analyses Spécifiques**

```javascript
// Revenus d'un vendeur spécifique
GET /api/vendor-analytics/revenue/123

// Top-produits d'un vendeur (limite 10)
GET /api/vendor-analytics/top-products/123?limit=10

// Statistiques des 30 derniers jours
GET /api/vendor-analytics/sales-stats/123?period=30

// Historique des 90 derniers jours
GET /api/vendor-analytics/sales-history/123?days=90
```

## 📊 **Données Retournées**

### **Revenus Vendeur**
```json
{
  "total_revenue": 1500.00,
  "total_orders": 25,
  "total_products_sold": 45
}
```

### **Top-Produits**
```json
[
  {
    "product_id": 1,
    "product_name": "T-shirt Rouge",
    "total_quantity": 15,
    "total_revenue": 450.00,
    "average_price": 30.00
  }
]
```

### **Statistiques de Vente**
```json
{
  "period_revenue": 500.00,
  "period_orders": 8,
  "period_products_sold": 12,
  "average_order_value": 62.50,
  "best_selling_product": "T-shirt Rouge",
  "best_selling_product_quantity": 5
}
```

### **Dashboard Complet**
```json
{
  "revenue": { ... },
  "topProducts": [ ... ],
  "salesStats": { ... },
  "salesHistory": [ ... ],
  "lastUpdated": "2024-01-15T10:30:00.000Z"
}
```

## 🔍 **Dépannage**

### **Problème : "Fonction non trouvée"**
```bash
# Vérifier que la migration a été appliquée
node test-vendor-analytics.js
```

### **Problème : "Aucune donnée"**
- Vérifier qu'il y a des commandes payées dans la base
- Vérifier que les produits sont liés aux bons vendeurs
- Vérifier que les paiements ont le statut "Payé"

### **Problème : "Erreur de permissions"**
- Vérifier que l'utilisateur est authentifié
- Vérifier que l'utilisateur est bien un vendeur
- Vérifier les politiques RLS dans Supabase

## 🎨 **Intégration Frontend**

### **React/Next.js**
```javascript
import { useState, useEffect } from 'react';

function VendorDashboard() {
    const [dashboard, setDashboard] = useState(null);
    
    useEffect(() => {
        fetch('/api/vendor-analytics/my-dashboard', {
            headers: { 'Authorization': `Bearer ${token}` }
        })
        .then(res => res.json())
        .then(data => setDashboard(data.data));
    }, []);
    
    return (
        <div>
            <h2>💰 Revenus: {dashboard?.revenue.total_revenue}€</h2>
            <h3>📦 Commandes: {dashboard?.revenue.total_orders}</h3>
            {/* ... */}
        </div>
    );
}
```

### **Vue.js**
```javascript
export default {
    data() {
        return {
            dashboard: null
        }
    },
    async mounted() {
        const response = await fetch('/api/vendor-analytics/my-dashboard');
        this.dashboard = (await response.json()).data;
    }
}
```

## 📈 **Performance**

- **Index optimisés** pour les requêtes d'analyse
- **Fonctions SQL** avec `SECURITY DEFINER` pour les performances
- **Vue matérialisée** pour les revenus globaux
- **Cache possible** au niveau application si nécessaire

## 🔐 **Sécurité**

- **Authentification requise** pour toutes les routes
- **Politiques RLS** respectées
- **Validation des paramètres** dans les contrôleurs
- **Gestion d'erreurs** complète

## 📝 **Notes Importantes**

1. **Les analyses ne comptent que les commandes payées** (statut "Payé")
2. **Les données sont calculées en temps réel** (pas de cache)
3. **Les fonctions SQL sont optimisées** pour de grandes quantités de données
4. **L'historique est limité** par défaut à 90 jours pour les performances

---

**🎉 Votre dashboard admin peut maintenant afficher les revenus et top-produits des vendeurs !** 