# 🔄 Alternative à Stripe CLI : ngrok

## Pourquoi utiliser ngrok ?

Stripe CLI (`stripe listen`) doit rester ouvert pour recevoir les webhooks. Avec ngrok, vous pouvez exposer votre localhost et configurer un webhook permanent.

## Installation et Configuration

### 1. Installer ngrok
```bash
# Via Homebrew (macOS)
brew install ngrok

# Ou télécharger depuis https://ngrok.com/
```

### 2. Créer un compte ngrok
- Allez sur https://ngrok.com/
- Créez un compte gratuit
- Récupérez votre authtoken

### 3. Configurer ngrok
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### 4. Exposer votre serveur
```bash
ngrok http 4000
```

### 5. Utiliser l'URL ngrok dans Stripe
- Copiez l'URL HTTPS fournie par ngrok (ex: `https://abc123.ngrok.io`)
- Ajoutez `/api/payments/webhook` à la fin
- Configurez cette URL dans votre dashboard Stripe

## Avantages
- ✅ Pas besoin de garder une commande ouverte
- ✅ URL permanente (avec compte payant)
- ✅ Interface web pour inspecter les requêtes
- ✅ Plus stable que Stripe CLI

## Inconvénients
- ❌ URL change à chaque redémarrage (version gratuite)
- ❌ Limite de connexions (version gratuite)

## Configuration dans votre projet

1. Démarrez votre serveur : `npm start`
2. Dans un autre terminal : `ngrok http 4000`
3. Copiez l'URL HTTPS et configurez-la dans Stripe Dashboard
4. Ajoutez le webhook secret à votre `.env`

## Exemple de configuration
```bash
# Terminal 1
npm start

# Terminal 2  
ngrok http 4000

# Puis dans Stripe Dashboard :
# URL: https://abc123.ngrok.io/api/payments/webhook
# Events: checkout.session.completed, payment_intent.payment_failed
``` 