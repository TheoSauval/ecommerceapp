#!/bin/bash

echo "🚀 Configuration des Webhooks Stripe"
echo "===================================="
echo ""

# Vérifier si Stripe CLI est installé
if ! command -v stripe &> /dev/null; then
    echo "❌ Stripe CLI n'est pas installé"
    echo "💡 Installation en cours..."
    brew install stripe/stripe-cli/stripe
    echo ""
fi

# Vérifier si l'utilisateur est connecté à Stripe
echo "🔍 Vérification de la connexion Stripe..."
if ! stripe config --list &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Stripe"
    echo "💡 Connexion en cours..."
    stripe login
    echo ""
fi

echo "✅ Stripe CLI configuré"
echo ""

# Instructions pour l'utilisateur
echo "📋 Étapes suivantes :"
echo "====================="
echo ""
echo "1. Ouvrez un nouveau terminal et démarrez l'écoute des webhooks :"
echo "   stripe listen --forward-to localhost:4000/api/payments/webhook"
echo ""
echo "2. Copiez l'URL du webhook affichée"
echo ""
echo "3. Dans ce terminal, créez le webhook :"
echo "   node setup-stripe-webhook.js --create"
echo ""
echo "4. Quand demandé, collez l'URL copiée"
echo ""
echo "5. Copiez le secret webhook et ajoutez-le à votre fichier .env"
echo ""
echo "6. Testez la configuration :"
echo "   node quick-payment-test.js"
echo ""

# Demander si l'utilisateur veut continuer
read -p "Voulez-vous continuer avec la création du webhook ? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Création du webhook..."
    echo "💡 Assurez-vous que Stripe CLI est en cours d'exécution dans un autre terminal"
    echo ""
    node setup-stripe-webhook.js --create
else
    echo "👋 Configuration annulée"
fi 