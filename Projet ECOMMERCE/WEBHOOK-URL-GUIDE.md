# Guide : Comment Obtenir l'URL du Webhook Stripe

## 🚨 Problème
Stripe ne peut pas envoyer des webhooks vers `localhost` car ce n'est pas accessible depuis Internet.

## 🔧 Solutions

### Option 1 : Stripe CLI (Recommandé pour le développement)

#### Étape 1 : Installer Stripe CLI
```bash
brew install stripe/stripe-cli/stripe
```

#### Étape 2 : Se connecter
```bash
stripe login
```

#### Étape 3 : Démarrer l'écoute des webhooks
```bash
stripe listen --forward-to localhost:4000/api/payments/webhook
```

**Résultat :** Vous verrez quelque chose comme :
```
> Ready! Your webhook signing secret is whsec_1234567890abcdef...
> Forwarding events to http://localhost:4000/api/payments/webhook
```

#### Étape 4 : Utiliser l'URL fournie
L'URL du webhook sera affichée dans la console. Utilisez-la pour créer le webhook :

```bash
node setup-stripe-webhook.js --create
```

Quand demandé, entrez l'URL affichée par Stripe CLI.

### Option 2 : ngrok (Alternative)

#### Étape 1 : Installer ngrok
```bash
brew install ngrok
```

#### Étape 2 : Créer un tunnel
```bash
ngrok http 4000
```

#### Étape 3 : Utiliser l'URL ngrok
Vous verrez quelque chose comme :
```
Forwarding https://abc123.ngrok.io -> http://localhost:4000
```

Utilisez `https://abc123.ngrok.io/api/payments/webhook` comme URL de webhook.

### Option 3 : Production

Pour la production, utilisez l'URL de votre serveur déployé :
```
https://votre-domaine.com/api/payments/webhook
```

## 🎯 Étapes Rapides

1. **Ouvrez un terminal et démarrez Stripe CLI :**
   ```bash
   stripe listen --forward-to localhost:4000/api/payments/webhook
   ```

2. **Copiez l'URL affichée** (ex: `https://webhook.site/abc123...`)

3. **Dans un autre terminal, créez le webhook :**
   ```bash
   node setup-stripe-webhook.js --create
   ```

4. **Quand demandé, collez l'URL copiée**

5. **Copiez le secret webhook** affiché et ajoutez-le à votre `.env`

## 📋 Exemple Complet

```bash
# Terminal 1 : Démarrer Stripe CLI
stripe listen --forward-to localhost:4000/api/payments/webhook

# Terminal 2 : Créer le webhook
node setup-stripe-webhook.js --create
# Entrez l'URL affichée par Stripe CLI

# Ajouter le secret à .env
echo "STRIPE_WEBHOOK_SECRET=whsec_votre_secret_ici" >> .env
```

## 🔍 Vérification

```bash
# Vérifier que tout fonctionne
node quick-payment-test.js
```

## ❓ Problèmes Courants

### "Invalid URL"
- Assurez-vous d'utiliser l'URL fournie par Stripe CLI ou ngrok
- N'utilisez pas `localhost` directement

### "Webhook not found"
- Vérifiez que Stripe CLI est en cours d'exécution
- Vérifiez que votre serveur écoute sur le port 4000

### "Connection refused"
- Démarrez votre serveur Node.js : `npm start`
- Vérifiez que le port 4000 est libre 