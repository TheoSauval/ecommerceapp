# Guide de Dépannage - Paiements Stripe

## Problèmes Identifiés et Solutions

### 1. Problème : Aucun enregistrement dans la table `payments` après un paiement réussi

**Cause probable :** Le webhook Stripe n'est pas configuré ou ne fonctionne pas correctement.

**Solutions :**

#### A. Vérifier la configuration des webhooks
```bash
# Vérifier la configuration actuelle
node setup-stripe-webhook.js --check

# Lister les webhooks existants
node setup-stripe-webhook.js --list

# Créer un nouveau webhook si nécessaire
node setup-stripe-webhook.js --create
```

#### B. Vérifier les variables d'environnement
Assurez-vous que votre fichier `.env` contient :
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

#### C. Vérifier les logs du serveur
Les logs améliorés affichent maintenant :
- Réception des webhooks
- Traitement des événements
- Création des paiements
- Erreurs détaillées

### 2. Problème : Pas de redirection après paiement réussi

**Cause probable :** L'URL scheme personnalisé n'est pas correctement géré.

**Solutions :**

#### A. Vérifier la configuration Info.plist
Assurez-vous que le fichier `Info.plist` contient :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>stripe-return</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ecommerceshop</string>
        </array>
    </dict>
</array>
```

#### B. Vérifier les URLs de redirection Stripe
Dans `paymentService.js`, les URLs sont configurées comme :
```javascript
success_url: `ecommerceshop://payment/success?session_id={CHECKOUT_SESSION_ID}`,
cancel_url: `ecommerceshop://payment/cancel`,
```

### 3. Problème : Erreurs de signature webhook

**Cause probable :** Le secret webhook ne correspond pas.

**Solutions :**

#### A. Régénérer le secret webhook
```bash
# Supprimer l'ancien webhook
node setup-stripe-webhook.js --list
# Notez l'ID du webhook à supprimer
node setup-stripe-webhook.js --delete [WEBHOOK_ID]

# Créer un nouveau webhook
node setup-stripe-webhook.js --create
```

#### B. Mettre à jour le fichier .env
Copiez le nouveau secret affiché dans votre fichier `.env`.

### 4. Problème : Paiements dupliqués

**Cause probable :** Le webhook est appelé plusieurs fois.

**Solution :** Le code vérifie maintenant si un paiement existe déjà avant d'en créer un nouveau.

### 5. Problème : Stock non décrémenté

**Cause probable :** La fonction `decrease_stock` échoue.

**Solution :** Vérifiez que la fonction SQL `decrease_stock` existe dans votre base de données.

## Tests de Diagnostic

### 1. Test de la configuration Stripe
```bash
node test-stripe-config.js
```

### 2. Test complet du processus de paiement
```bash
node test-stripe-payment.js
```

### 3. Test des webhooks
```bash
# Créer un webhook de test
node setup-stripe-webhook.js --create

# Tester le webhook
node setup-stripe-webhook.js --test [WEBHOOK_ID]
```

## Logs de Débogage

### Logs du serveur
Les logs améliorés affichent :
- `🔔 Réception webhook Stripe`
- `🔔 Traitement webhook Stripe: checkout.session.completed`
- `✅ Paiement créé avec succès: ID [ID]`
- `❌ Erreur lors de la création du paiement`

### Logs de l'application Swift
Les logs affichent :
- `🔗 URL reçue: [URL]`
- `🔗 URL scheme ecommerceshop détectée`
- `✅ Paiement réussi, session ID: [ID]`

## Configuration Recommandée

### 1. Variables d'environnement
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
WEBHOOK_URL=http://localhost:4000/api/payments/webhook
```

### 2. Événements webhook requis
- `checkout.session.completed`
- `payment_intent.payment_failed`
- `payment_intent.succeeded`

### 3. URLs de redirection
- Success: `ecommerceshop://payment/success?session_id={CHECKOUT_SESSION_ID}`
- Cancel: `ecommerceshop://payment/cancel`

## Vérification Rapide

1. **Vérifier les webhooks :** `node setup-stripe-webhook.js --check`
2. **Tester un paiement :** `node test-stripe-payment.js`
3. **Vérifier les logs :** Surveiller les logs du serveur pendant un paiement
4. **Vérifier la base de données :** Contrôler la table `payments` après un paiement

## Support

Si les problèmes persistent :
1. Vérifiez les logs détaillés
2. Testez avec les scripts fournis
3. Vérifiez la configuration Stripe dans le dashboard
4. Assurez-vous que le serveur est accessible depuis Stripe 