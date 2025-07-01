# 🔧 Dépannage Webhook Stripe - Commandes non mises à jour

## Problème identifié
Le paiement Stripe se passe correctement côté client, mais :
- ❌ Les commandes restent en statut "En attente" au lieu de "Payé"
- ❌ Aucun enregistrement n'est créé dans la table `payments`
- ❌ Le webhook Stripe ne fonctionne pas correctement

## 🔍 Diagnostic

### 1. Vérifier la configuration du webhook
```bash
cd "/Users/enzoga/Desktop/ecommerceapp-SWIFT/Projet ECOMMERCE"
node check-webhook-status.js
```

### 2. Tester le traitement manuel du webhook
```bash
node test-webhook-manual.js
```

## 🛠️ Solutions

### Solution 1: Configuration du webhook en développement

#### Option A: Utiliser Stripe CLI (Recommandé)
```bash
# 1. Installer Stripe CLI
brew install stripe/stripe-cli/stripe

# 2. Se connecter
stripe login

# 3. Démarrer l'écoute des webhooks
stripe listen --forward-to localhost:4000/api/payments/webhook

# 4. Copier l'URL du webhook affichée (ex: https://webhook.site/abc123...)
# 5. Créer le webhook avec cette URL
node setup-stripe-webhook.js
```

#### Option B: Utiliser ngrok
```bash
# 1. Installer ngrok
brew install ngrok

# 2. Démarrer ngrok
ngrok http 4000

# 3. Utiliser l'URL https://...ngrok.io/api/payments/webhook
# 4. Créer le webhook avec cette URL
node setup-stripe-webhook.js
```

### Solution 2: Vérifier les variables d'environnement

Assurez-vous que votre fichier `.env` contient :
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...  # Clé fournie lors de la création du webhook
WEBHOOK_URL=https://...  # URL du webhook (optionnel)
```

### Solution 3: Vérifier les logs du serveur

Démarrez votre serveur Node.js et surveillez les logs :
```bash
cd "/Users/enzoga/Desktop/ecommerceapp-SWIFT/Projet ECOMMERCE"
npm start
```

Puis effectuez un paiement et vérifiez les logs pour voir si le webhook est reçu.

## 🔄 Corrections apportées

### 1. Correction des IDs de commande
- ✅ Les IDs de commande sont maintenant des UUIDs (strings)
- ✅ Le code du webhook a été mis à jour pour gérer les UUIDs
- ✅ Suppression des conversions `parseInt()` inutiles

### 2. Amélioration du logging
- ✅ Ajout de logs détaillés dans le webhook
- ✅ Meilleure gestion des erreurs
- ✅ Vérification des données reçues

## 📋 Checklist de vérification

- [ ] Webhook Stripe configuré et actif
- [ ] `STRIPE_WEBHOOK_SECRET` configuré dans `.env`
- [ ] Serveur Node.js accessible depuis l'extérieur (ngrok ou déploiement)
- [ ] Événements `checkout.session.completed` activés dans le webhook
- [ ] Logs du serveur montrent la réception des webhooks
- [ ] Test manuel du webhook fonctionne

## 🧪 Tests à effectuer

### Test 1: Vérification de la configuration
```bash
node check-webhook-status.js
```

### Test 2: Test manuel du webhook
```bash
node test-webhook-manual.js
```

### Test 3: Test complet du paiement
1. Créer une commande via l'app
2. Effectuer le paiement Stripe
3. Vérifier les logs du serveur
4. Vérifier le statut de la commande dans Supabase
5. Vérifier l'enregistrement de paiement dans Supabase

## 🚨 Problèmes courants

### 1. "Signature Stripe manquante"
- Vérifier que `STRIPE_WEBHOOK_SECRET` est configuré
- Vérifier que le webhook est configuré avec la bonne URL

### 2. "Commande non trouvée"
- Vérifier que l'ID de commande dans les métadonnées est correct
- Vérifier que la commande existe dans la base de données

### 3. "Erreur lors de la création du paiement"
- Vérifier la structure de la table `payments`
- Vérifier les contraintes de clés étrangères

## 📞 Support

Si le problème persiste après avoir suivi ce guide :
1. Vérifiez les logs du serveur
2. Vérifiez les logs Stripe dans le dashboard
3. Testez avec le script de test manuel
4. Vérifiez la configuration du webhook 