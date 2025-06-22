# Tests de Paiement Stripe

Ce dossier contient une suite complète de tests pour vérifier l'intégration Stripe avec votre base de données Supabase.

## 📁 Fichiers de Test

- **`test-stripe-payment.js`** - Tests principaux de paiement Stripe
- **`test-stripe-config.js`** - Configuration et vérifications préalables
- **`run-stripe-tests.js`** - Script d'exécution simple
- **`README-TESTS-STRIPE.md`** - Ce fichier de documentation

## 🚀 Prérequis

### 1. Variables d'Environnement

Créez un fichier `.env` à la racine du projet avec :

```env
# Supabase (requis)
SUPABASE_URL=votre_url_supabase
SUPABASE_ANON_KEY=votre_clé_anon_supabase

# Stripe (requis)
STRIPE_SECRET_KEY=sk_test_votre_clé_secrète_stripe

# Stripe (optionnel - pour les tests complets)
STRIPE_WEBHOOK_SECRET=whsec_votre_clé_webhook_stripe

# Frontend (optionnel)
FRONTEND_URL=http://localhost:3000
```

**Note :** Le `STRIPE_WEBHOOK_SECRET` est optionnel. Sans lui, les tests utiliseront une simulation directe du paiement.

### 2. Données de Test

Assurez-vous d'avoir dans votre base de données :
- ✅ Des produits actifs dans la table `products`
- ✅ Des variantes en stock dans `product_variants`
- ✅ Des vendeurs dans `vendors`
- ✅ Des couleurs et tailles dans `colors` et `heights`

### 3. Dépendances

```bash
npm install stripe dotenv
```

## 🧪 Exécution des Tests

### Méthode 1 : Script simple
```bash
node run-stripe-tests.js
```

### Méthode 2 : Tests individuels
```bash
# Vérifications préalables uniquement
node test-stripe-config.js

# Tests de paiement complets
node test-stripe-payment.js
```

### Méthode 3 : Via npm (si configuré)
```bash
npm run test:stripe
```

## 📋 Tests Inclus

### 1. Vérifications Préalables
- ✅ Variables d'environnement configurées
- ✅ Connexion à Supabase établie
- ✅ Connexion à Stripe établie
- ✅ Données de test présentes

### 2. Tests de Base de Données
- ✅ Vérification des produits existants
- ✅ Vérification des variantes en stock
- ✅ Création d'un utilisateur test

### 3. Tests de Commande
- ✅ Création d'une commande test
- ✅ Ajout de variantes à la commande

### 4. Tests Stripe
- ✅ Création de session de paiement
- ✅ Simulation de webhook de paiement
- ✅ Test de remboursement

### 5. Nettoyage
- ✅ Suppression des données de test
- ✅ Suppression de l'utilisateur test

## 💳 Cartes de Test Stripe

Les tests utilisent les cartes de test Stripe suivantes :

| Carte | Numéro | Résultat |
|-------|--------|----------|
| Paiement réussi | `4242424242424242` | ✅ Succès |
| Paiement refusé | `4000000000000002` | ❌ Refusé |
| Fonds insuffisants | `4000000000009995` | ❌ Fonds insuffisants |
| Carte expirée | `4000000000000069` | ❌ Expirée |
| CVC incorrect | `4000000000000127` | ❌ CVC invalide |

## 🔧 Configuration Avancée

### Personnaliser les Tests

Modifiez `test-stripe-config.js` pour ajuster :

```javascript
const testConfig = {
    testUser: {
        email: 'votre-email-test@example.com',
        password: 'VotreMotDePasse123!',
        // ...
    },
    testOrder: {
        quantity: 1, // Quantité de test
        adresse_livraison: 'Votre adresse de test',
        // ...
    }
};
```

### Ajouter de Nouveaux Tests

Dans `test-stripe-payment.js`, ajoutez de nouvelles méthodes :

```javascript
async testNouveauFonctionnalite() {
    console.log('\n🔍 Test: Nouvelle fonctionnalité...');
    // Votre logique de test
    return true;
}
```

## 🚨 Dépannage

### Erreur de Connexion Supabase
```
❌ Erreur de connexion à Supabase
```
**Solution :** Vérifiez vos variables `SUPABASE_URL` et `SUPABASE_ANON_KEY`

### Erreur de Connexion Stripe
```
❌ Erreur de connexion à Stripe
```
**Solution :** Vérifiez votre `STRIPE_SECRET_KEY` et assurez-vous qu'elle est en mode test

### Aucun Produit Trouvé
```
❌ Aucun produit actif trouvé dans la base de données
```
**Solution :** Ajoutez des produits dans votre base de données ou désactivez le filtre `actif = true`

### Webhook Non Configuré
```
⚠️  Variables d'environnement optionnelles manquantes:
   - STRIPE_WEBHOOK_SECRET (utilisera les valeurs par défaut)
```
**Solution :** C'est normal ! Les tests utiliseront une simulation directe du paiement.

## 📊 Résultats Attendus

### Avec Webhook Configuré
```
🚀 DÉBUT DES TESTS DE PAIEMENT STRIPE
=====================================

🔍 Test 1: Vérification des produits existants...
✅ 3 produits trouvés:
   - T-shirt Blanc (25.00€)
   - Sweat Gris (45.00€)
   - Doudoune (89.99€)

🔍 Test 2: Vérification des variantes existantes...
✅ 5 variantes en stock trouvées:
   - T-shirt Blanc (Blanc, M) - 25.00€ - Stock: 10

🔍 Test 3: Création d'un utilisateur test...
✅ Utilisateur test créé: test-1234567890@example.com

🔍 Test 4: Création d'une commande test...
✅ Commande créée: ID 123, Total: 50.00€

🔍 Test 5: Test de création de session Stripe...
✅ Session Stripe créée: cs_test_...
   URL de paiement: https://checkout.stripe.com/...
   Montant total: 50.00€

🔍 Test 6: Test de webhook Stripe (simulation)...
✅ Webhook traité avec succès
   Statut de la commande: Payé
   Paiement créé: ID 456, Statut: Payé

🔍 Test 7: Test de remboursement...
✅ Remboursement créé: re_...
   Montant remboursé: 50.00€

🎉 TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS !
```

### Sans Webhook (Simulation)
```
🚀 DÉBUT DES TESTS DE PAIEMENT STRIPE
=====================================

🔍 Test 1: Vérification des produits existants...
✅ 3 produits trouvés

🔍 Test 2: Vérification des variantes existantes...
✅ 5 variantes en stock trouvées

🔍 Test 3: Création d'un utilisateur test...
✅ Utilisateur test créé

🔍 Test 4: Création d'une commande test...
✅ Commande créée: ID 123, Total: 50.00€

🔍 Test 5: Test de création de session Stripe...
✅ Session Stripe créée: cs_test_...
   URL de paiement: https://checkout.stripe.com/...
   Montant total: 50.00€

🔍 Test 6: Test de webhook Stripe (simulation)...
❌ Erreur lors du test du webhook
💡 Note: Le webhook secret n'est pas configuré, mais les tests de base fonctionnent

🔄 Tentative avec simulation directe...
🔍 Test 6b: Simulation directe de paiement (sans webhook)...
✅ Commande mise à jour: Statut Payé
✅ Paiement simulé créé: ID 456, Statut: Payé

🔍 Test 7: Test de remboursement...
💡 Paiement simulé détecté, simulation du remboursement...
✅ Remboursement simulé créé
   Montant remboursé: 50.00€

🎉 TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS !
```

## 🔒 Sécurité

- ⚠️ **Ne jamais** utiliser les clés de production dans les tests
- ⚠️ **Toujours** utiliser le mode test de Stripe
- ⚠️ **Vérifier** que les données de test sont bien supprimées
- ⚠️ **Ne pas** commiter les clés secrètes dans Git

## 📞 Support

En cas de problème :
1. Vérifiez les logs d'erreur détaillés
2. Consultez la documentation Stripe
3. Vérifiez la configuration Supabase
4. Contactez l'équipe de développement