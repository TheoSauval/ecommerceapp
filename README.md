# 🛍️ E-COMMERCE APP - PROJET COMPLET

## 📋 Vue d'ensemble

Application e-commerce complète avec **application mobile iOS native** (Swift/SwiftUI), **dashboard admin web** (React/Material-UI) et **API backend robuste** (Node.js/Express/Supabase).

### 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   📱 iOS App    │    │   🔧 Backend     │    │   🌐 Dashboard    │
│   (SwiftUI)     │◄──►│   (Node.js)     │◄──►│   (React)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │
        ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│   💳 Stripe     │    │   🗄️ Supabase   │
│   (Paiements)   │     │   (PostgreSQL)  │
└─────────────────┘     └─────────────────┘
```

---

## 🚀 Technologies Utilisées

### **Backend**
- **Node.js** + **Express.js** - API RESTful
- **Supabase** - Base de données PostgreSQL + Stockage
- **Stripe** - Paiements sécurisés
- **JWT** - Authentification

### **Mobile (iOS)**
- **SwiftUI** - Interface utilisateur
- **Combine** - Programmation réactive
- **URLSession** - Appels API
- **Core Data** - Cache local

### **Dashboard Admin**
- **React.js** - Interface web
- **Material-UI** - Design system
- **Axios** - Appels HTTP
- **React Router** - Navigation

---

## 📱 Application Mobile iOS

### 🏠 **Pages Principales**
- **Accueil** - Produits en vedette et recommandations
- **Boutique** - Catalogue avec filtres dynamiques
- **Panier** - Gestion des articles et checkout
- **Commandes** - Historique et suivi
- **Profil** - Gestion du compte utilisateur

### 🛍️ **Fonctionnalités Produits**
- ✅ Catalogue avec images et descriptions
- ✅ Filtrage par catégories (T-Shirt, Sweat, Manteau, Pantalon)
- ✅ Système de recommandations personnalisées
- ✅ Recherche full-text
- ✅ Variantes (couleur/taille) avec gestion du stock
- ✅ Produits favoris

### 🛒 **Gestion Panier**
- ✅ Ajout/suppression d'articles
- ✅ Modification des quantités
- ✅ Calcul automatique des prix
- ✅ Validation du stock en temps réel
- ✅ Vider le panier

### 💳 **Processus d'Achat**
- ✅ Checkout sécurisé
- ✅ Intégration Stripe
- ✅ Confirmation de commande
- ✅ Gestion des erreurs

### 👤 **Gestion Utilisateur**
- ✅ Inscription/Connexion
- ✅ Profil personnalisable
- ✅ Changement de mot de passe
- ✅ Historique des commandes

---

## 🌐 Dashboard Admin Web

### 📊 **Dashboard Principal**
- **Vue d'ensemble** - Statistiques globales
- **Graphiques** - Évolution des ventes
- **Métriques clés** - CA, commandes, produits

### 🛍️ **Gestion Produits**
- ✅ Liste avec pagination
- ✅ Création/édition de produits
- ✅ Upload d'images (drag & drop)
- ✅ Gestion des variantes
- ✅ Activation/désactivation

### 📋 **Gestion Commandes**
- ✅ Toutes les commandes reçues
- ✅ Détails complets (client, produits, statut)
- ✅ Mise à jour du statut
- ✅ Filtres avancés

### 📈 **Analyses**
- ✅ Statistiques de vente
- ✅ Produits populaires
- ✅ Revenus par période
- ✅ Performance vendeur

---

## 🔧 API Backend

### 🔐 **Authentification** (`/api/auth`)
```
POST /register          # Création de compte
POST /login            # Connexion
POST /logout           # Déconnexion
POST /refresh          # Rafraîchir session
POST /reset            # Demande reset mot de passe
PUT  /reset            # Reset mot de passe
PUT  /change-password  # Changer mot de passe
GET  /profile          # Profil utilisateur
PUT  /profile          # Mettre à jour profil
```

### 🛍️ **Produits** (`/api/products`)
```
GET  /                 # Liste paginée
GET  /search           # Recherche full-text
GET  /categories       # Catégories disponibles
GET  /category/:cat    # Produits par catégorie
GET  /:id              # Détails produit
POST /                 # Créer produit (vendeur)
PUT  /:id              # Modifier produit
DELETE /:id            # Supprimer produit
```

### 🛒 **Panier** (`/api/cart`)
```
GET  /                 # Récupérer panier
POST /                 # Ajouter au panier
PUT  /:itemId          # Modifier article
DELETE /clear          # Vider panier
DELETE /:itemId        # Supprimer article
```

### ❤️ **Favoris** (`/api/users/me/favorites`)
```
GET  /                 # Récupérer favoris
POST /                 # Ajouter favori
DELETE /:id            # Supprimer favori
```

### 📦 **Commandes** (`/api/orders`)
```
GET  /                 # Récupérer commandes
POST /                 # Créer commande
GET  /:id              # Détails commande
POST /:id/cancel       # Annuler commande
```

### 💳 **Paiements** (`/api/payments`)
```
POST /webhook          # Webhook Stripe
POST /                 # Créer paiement
GET  /                 # Récupérer paiements
GET  /:id              # Détails paiement
PUT  /:id/status       # Mettre à jour statut
POST /stripe/initiate  # Initier paiement Stripe
GET  /stripe/:orderId/status # Statut paiement
```

### 🧠 **Recommandations** (`/api/recommendations`)
```
POST /view             # Enregistrer consultation
PUT  /duration         # Mettre à jour durée
GET  /                 # Récupérer recommandations
GET  /categories       # Préférences catégories
GET  /analytics        # Statistiques utilisateur
GET  /history          # Historique consultation
GET  /popular          # Produits populaires
```

### 📊 **Analyses Vendeur** (`/api/vendor-analytics`)
```
GET  /my-dashboard     # Dashboard vendeur
GET  /revenue/:id      # Revenus vendeur
GET  /top-products/:id # Top produits
GET  /sales-stats/:id  # Statistiques vente
GET  /sales-history/:id # Historique ventes
GET  /dashboard/:id    # Dashboard complet
GET  /all-revenues     # Tous les revenus (admin)
GET  /global-stats     # Statistiques globales
```

### 🔔 **Notifications** (`/api/notifications`)
```
GET  /                 # Récupérer notifications
POST /                 # Créer notification
PUT  /:id              # Modifier notification
DELETE /:id            # Supprimer notification
PUT  /:id/read         # Marquer comme lu
PUT  /read-all         # Marquer tout comme lu
GET  /unread-count     # Nombre non lues
DELETE /clear-all      # Supprimer toutes
```

### 🛠️ **Admin** (`/api/admin`)
```
# Produits
GET  /products         # Tous les produits vendeur
GET  /products/colors  # Couleurs disponibles
GET  /products/heights # Tailles disponibles
POST /products         # Créer produit
PUT  /products/:id     # Modifier produit
DELETE /products/:id   # Supprimer produit

# Commandes
GET  /orders           # Toutes les commandes
GET  /orders/:id       # Détails commande
PUT  /orders/:id/status # Mettre à jour statut

# Dashboard
GET  /dashboard/sales  # Statistiques vente
GET  /dashboard/top-products # Produits populaires

# Upload
POST /upload/images    # Upload images produits
```

---

## 🗄️ Base de Données (Supabase)

### 📊 **Tables Principales**
```sql
users              # Utilisateurs et vendeurs
products           # Catalogue de produits
product_variants   # Variantes (couleur/taille/stock)
colors             # Couleurs disponibles
heights            # Tailles disponibles
orders             # Commandes
order_variants     # Articles commandés
cart_items         # Panier utilisateur
favorites          # Produits favoris
history            # Historique de consultation
notifications      # Notifications utilisateur
payments           # Transactions de paiement
```

### 🔧 **Fonctionnalités Avancées**
- **Triggers automatiques** - Mise à jour des stocks
- **Fonctions SQL** - Calculs de recommandations
- **Policies RLS** - Sécurité des données
- **Stockage d'images** - Supabase Storage

---

## 🔐 Sécurité

### 🛡️ **Authentification**
- **JWT Tokens** - Authentification sécurisée
- **Refresh Tokens** - Renouvellement automatique
- **Validation des données** - Sanitisation des entrées
- **CORS** - Configuration sécurisée
- **Rate Limiting** - Protection contre les abus

### 🔒 **Paiements**
- **Stripe** - Paiements sécurisés
- **Webhooks** - Notifications en temps réel
- **Validation** - Vérification des transactions

---

## ⚡ Performance

### 🚀 **Optimisations**
- **Pagination** - Chargement progressif
- **Cache** - Mise en cache des données
- **Optimisation requêtes** - Index et jointures optimisées
- **Compression** - Réduction de la taille des données

### 📊 **Monitoring**
- **Logs détaillés** - Traçabilité complète
- **Gestion d'erreurs** - Messages d'erreur clairs
- **Métriques** - Suivi des performances

---

## 📁 Structure du Projet

```
ecommerceapp-SWIFT/
├── 📱 E-commerceShop/              # Application iOS
│   ├── E_commerceShopApp.swift     # Point d'entrée
│   ├── ContentView.swift           # Vue principale
│   ├── HomeView.swift              # Page d'accueil
│   ├── ProductDetailView.swift     # Détails produit
│   ├── CartView.swift              # Panier
│   ├── OrdersView.swift            # Commandes
│   ├── CheckoutView.swift          # Processus d'achat
│   ├── Login.swift                 # Connexion
│   ├── RegisterView.swift          # Inscription
│   ├── ProfileView.swift           # Profil utilisateur
│   ├── FavoritesView.swift         # Favoris
│   ├── Services/                   # Services API
│   │   ├── APIConfig.swift         # Configuration API
│   │   ├── AuthService.swift       # Service authentification
│   │   ├── ProductService.swift    # Service produits
│   │   ├── CartService.swift       # Service panier
│   │   ├── OrderService.swift      # Service commandes
│   │   ├── PaymentService.swift    # Service paiements
│   │   ├── FavoriteService.swift   # Service favoris
│   │   ├── NotificationService.swift # Service notifications
│   │   ├── RecommendationService.swift # Service recommandations
│   │   └── CategoryService.swift   # Service catégories
│   └── Models.swift                # Modèles de données
│
├── 🌐 admin-dashboard/             # Dashboard Admin
│   ├── src/
│   │   ├── App.jsx                 # Application principale
│   │   ├── pages/                  # Pages principales
│   │   │   ├── Dashboard.jsx       # Dashboard principal
│   │   │   ├── Products.jsx        # Gestion produits
│   │   │   ├── Orders.jsx          # Gestion commandes
│   │   │   ├── Login.jsx           # Connexion
│   │   │   └── Register.jsx        # Inscription
│   │   ├── components/             # Composants réutilisables
│   │   │   └── Layout.jsx          # Layout principal
│   │   └── context/                # Context React
│   └── public/                     # Fichiers statiques
│
└── 🔧 Projet ECOMMERCE/            # Backend API
    ├── app.js                      # Point d'entrée principal
    ├── routes/                     # Définition des routes API
    │   ├── auth.js                 # Authentification
    │   ├── products.js             # Gestion produits
    │   ├── orders.js               # Gestion commandes
    │   ├── cart.js                 # Gestion panier
    │   ├── favorites.js            # Gestion favoris
    │   ├── payments.js             # Gestion paiements
    │   ├── recommendations.js      # Système recommandations
    │   ├── vendorAnalytics.js      # Analyses vendeur
    │   ├── notifications.js        # Gestion notifications
    │   ├── user.js                 # Gestion utilisateurs
    │   └── admin/                  # Routes admin
    │       ├── products.js         # Gestion produits admin
    │       ├── orders.js           # Gestion commandes admin
    │       ├── dashboard.js        # Dashboard admin
    │       └── upload.js           # Upload d'images
    ├── controllers/                # Logique métier
    ├── services/                   # Services métier
    ├── middleware/                 # Middlewares Express
    ├── config/                     # Configuration
    └── migrations/                 # Scripts de migration DB
```

---

## 🚀 Installation & Démarrage

### **1. Backend**
```bash
cd "Projet ECOMMERCE"
npm install
npm start
```

### **2. Dashboard Admin**
```bash
cd admin-dashboard
npm install
npm start
```

### **3. Application iOS**
- Ouvrir `E-commerceShop.xcodeproj` dans Xcode
- Configurer les variables d'environnement
- Lancer sur simulateur ou appareil

---

## 🎯 Fonctionnalités Clés

### **🛍️ E-commerce Complet**
- ✅ Catalogue de produits avec variantes
- ✅ Système de panier avancé
- ✅ Processus d'achat sécurisé
- ✅ Gestion des commandes
- ✅ Système de favoris
- ✅ Recherche et filtrage

### **🧠 Intelligence Artificielle**
- ✅ Système de recommandations personnalisées
- ✅ Tracking du comportement utilisateur
- ✅ Analyse des préférences
- ✅ Produits populaires

### **📊 Analytics & Reporting**
- ✅ Dashboard vendeur complet
- ✅ Statistiques de vente
- ✅ Analyses de performance
- ✅ Rapports détaillés

### **🔐 Sécurité Avancée**
- ✅ Authentification JWT
- ✅ Gestion des sessions
- ✅ Validation des données
- ✅ Protection contre les abus

### **📱 Multi-Plateforme**
- ✅ Application mobile native (iOS)
- ✅ Dashboard web admin
- ✅ API RESTful complète
- ✅ Synchronisation en temps réel

---

**Développé avec ❤️ par Enzo et Théo** 