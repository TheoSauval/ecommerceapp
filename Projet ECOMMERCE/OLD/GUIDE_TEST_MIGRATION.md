# 🚀 Guide de Migration vers Supabase Auth

Ce guide vous accompagne dans la migration de votre application e-commerce vers **Supabase Auth** avec une base de données cloud PostgreSQL.

## 📋 Prérequis

- Un compte Supabase (gratuit sur [supabase.com](https://supabase.com))
- Node.js installé
- Votre projet e-commerce existant

## 🔧 Étape 1: Configuration Supabase

### 1.1 Créer un projet Supabase
1. Connectez-vous à [supabase.com](https://supabase.com)
2. Cliquez sur "New Project"
3. Choisissez votre organisation
4. Donnez un nom à votre projet (ex: "ecommerce-app")
5. Créez un mot de passe pour la base de données
6. Choisissez une région proche de vos utilisateurs
7. Cliquez sur "Create new project"

### 1.2 Récupérer les clés d'API
1. Dans votre projet Supabase, allez dans **Settings > API**
2. Copiez les informations suivantes :
   - **Project URL** (ex: `https://your-project.supabase.co`)
   - **anon public** (clé publique)
   - **service_role** (clé secrète - à garder privée)

## 🗄️ Étape 2: Création de la Base de Données

### 2.1 Exécuter le script SQL
1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Cliquez sur "New query"
3. Copiez le contenu du fichier `supabase-schema.sql`
4. Cliquez sur "Run" pour exécuter le script

**Ce script crée :**
- ✅ Table `user_profiles` (extension de `auth.users`)
- ✅ Table `vendors` pour les vendeurs
- ✅ Table `products` pour les produits
- ✅ Table `orders` et `orders_products` pour les commandes
- ✅ Table `cart_items` pour le panier
- ✅ Tables `colors` et `heights` pour les variantes
- ✅ Table `favorites` pour les favoris
- ✅ Table `notifications` pour les notifications
- ✅ Table `payments` pour les paiements
- ✅ Index pour les performances
- ✅ Triggers pour `updated_at`
- ✅ Politiques RLS (Row Level Security)
- ✅ Trigger automatique pour créer les profils

### 2.2 Vérifier la création
1. Allez dans **Table Editor**
2. Vérifiez que toutes les tables sont créées
3. Vérifiez que les politiques RLS sont actives

## ⚙️ Étape 3: Configuration Backend

### 3.1 Installer les dépendances
```bash
npm install @supabase/supabase-js
```

### 3.2 Configurer l'environnement
1. Copiez `env.example` vers `.env`
2. Remplissez les variables Supabase :

```env
# Configuration Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Configuration de l'application
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:3001
```

### 3.3 Vérifier la configuration
Le fichier `config/supabase.js` est déjà configuré avec :
- ✅ Client Supabase avec clé de service (pour les opérations admin)
- ✅ Client Supabase public (pour l'authentification côté client)

## 🧪 Étape 4: Tests de Migration

### 4.1 Lancer les tests automatiques
```bash
node test-supabase.js
```

**Ce script teste :**
- ✅ Inscription d'utilisateurs
- ✅ Connexion/déconnexion
- ✅ Récupération et mise à jour de profils
- ✅ Création automatique de profils vendeurs
- ✅ Création de produits avec couleurs/tailles
- ✅ Politiques de sécurité RLS

### 4.2 Vérifier les résultats
Le script affiche :
```
🎉 Tous les tests d'authentification sont passés !
🎉 Tous les tests de base de données sont passés !
```

## 🔐 Étape 5: Authentification Supabase Auth

### 5.1 Avantages de Supabase Auth
- ✅ **Sécurité renforcée** : Gestion automatique des sessions
- ✅ **Fonctionnalités avancées** : Reset password, email verification
- ✅ **Intégration native** : Plus facile pour votre app Swift
- ✅ **Moins de code** : Pas besoin de gérer JWT manuellement

### 5.2 Structure des données
- **`auth.users`** : Table native Supabase (email, password, etc.)
- **`user_profiles`** : Extension avec vos champs (nom, prenom, age, role)
- **Trigger automatique** : Création du profil lors de l'inscription

### 5.3 API d'authentification
```javascript
// Inscription
POST /api/auth/register
{
  "nom": "Dupont",
  "prenom": "Jean",
  "age": 25,
  "mail": "jean@example.com",
  "password": "password123",
  "role": "user"
}

// Connexion
POST /api/auth/login
{
  "mail": "jean@example.com",
  "password": "password123"
}

// Réponse avec session
{
  "user": { "id": "uuid", "nom": "Dupont", ... },
  "session": {
    "access_token": "...",
    "refresh_token": "...",
    "expires_at": 1234567890
  }
}
```

## 🛡️ Étape 6: Sécurité RLS

### 6.1 Politiques de sécurité
Le schéma inclut des politiques RLS pour :
- ✅ **Utilisateurs** : Accès à leur propre profil
- ✅ **Vendeurs** : Gestion de leurs produits
- ✅ **Admins** : Accès complet
- ✅ **Produits** : Lecture publique, écriture vendeur/admin
- ✅ **Commandes** : Utilisateurs voient leurs commandes
- ✅ **Panier** : Utilisateurs gèrent leur panier

### 6.2 Utilisation des tokens
```javascript
// Dans vos requêtes API
const response = await fetch('/api/products', {
  headers: {
    'Authorization': `Bearer ${session.access_token}`
  }
});
```

## 📱 Étape 7: Intégration App Swift

### 7.1 Configuration Swift
```swift
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://your-project.supabase.co")!,
  supabaseKey: "your-anon-key"
)
```

### 7.2 Authentification Swift
```swift
// Inscription
let authResponse = try await supabase.auth.signUp(
  email: "user@example.com",
  password: "password123",
  data: [
    "nom": "Dupont",
    "prenom": "Jean",
    "age": 25,
    "role": "user"
  ]
)

// Connexion
let session = try await supabase.auth.signIn(
  email: "user@example.com",
  password: "password123"
)
```

## 🔄 Étape 8: Migration des Données (Optionnel)

Si vous avez des données existantes :

### 8.1 Exporter depuis MySQL
```sql
-- Exporter les utilisateurs
SELECT * FROM users INTO OUTFILE 'users.csv';

-- Exporter les produits
SELECT * FROM products INTO OUTFILE 'products.csv';
```

### 8.2 Importer dans Supabase
1. Utilisez l'interface **Table Editor** de Supabase
2. Ou utilisez l'API d'import de Supabase
3. Adaptez les formats de données si nécessaire

## ✅ Vérification Finale

### 8.1 Tests manuels
1. **Inscription** : Créez un compte via l'API
2. **Connexion** : Connectez-vous et vérifiez le token
3. **Profil** : Récupérez et modifiez le profil
4. **Produits** : Créez et listez des produits
5. **Sécurité** : Vérifiez que les politiques RLS fonctionnent

### 8.2 Vérification dans Supabase
1. **Authentication > Users** : Voir les utilisateurs créés
2. **Table Editor** : Vérifier les données dans les tables
3. **Logs** : Vérifier les requêtes dans les logs

## 🎉 Félicitations !

Votre migration vers Supabase Auth est terminée ! Vous bénéficiez maintenant de :
- ✅ Base de données cloud PostgreSQL
- ✅ Authentification sécurisée
- ✅ Politiques de sécurité RLS
- ✅ Intégration facile avec votre app Swift
- ✅ Scalabilité et performance

## 🆘 Support

En cas de problème :
1. Vérifiez les logs dans Supabase Dashboard
2. Consultez la [documentation Supabase](https://supabase.com/docs)
3. Vérifiez vos variables d'environnement
4. Relancez les tests avec `node test-supabase.js` 