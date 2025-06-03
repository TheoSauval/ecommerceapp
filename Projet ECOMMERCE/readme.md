1. Routes pour l’application mobile (Swift)
1.1 Authentification
Méthode
URL
Description
POST
/api/auth/register
Création d’un compte utilisateur (nom, prénom, mail, mot de passe)
POST
/api/auth/login
Connexion (renvoie un JWT et un refreshToken)
POST
/api/auth/refresh
Rafraîchir le token JWT
POST
/api/auth/reset
Demande de mail de réinitialisation
PUT
/api/auth/reset/:token
Changer le mot de passe via token

Fichiers
routes/auth.js


controllers/authController.js


middleware/auth.js



1.2 Gestion du profil
Méthode
URL
Description
GET
/api/users/me
Récupérer les infos du profil
PUT
/api/users/me
Mettre à jour le profil (adresse, nom, etc.)
DELETE
/api/users/me
Supprimer/archiver son compte

Fichiers
routes/users.js


controllers/userController.js



1.3 Catalogue de produits
Méthode
URL
Description
GET
/api/products
Liste paginée de tous les produits (filtres catégorie, prix, marque...)
GET
/api/products/:id
Détails d’un produit (prix, stock, tailles, couleurs, description, images)
GET
/api/products/search
Recherche full-text (q=…) + filtres avancés

Fichiers
routes/products.js


controllers/productController.js



1.4 Favoris & Panier
Méthode
URL
Description
GET
/api/users/me/favorites
Récupérer la liste des favoris
POST
/api/users/me/favorites
Ajouter un produit aux favoris ({ productId })
DELETE
/api/users/me/favorites/:id
Retirer un produit des favoris
GET
/api/cart
Récupérer le contenu du panier
POST
/api/cart
Ajouter un produit ({ productId, quantité, taille, couleur })
PUT
/api/cart/:itemId
Modifier quantité ou variante d’un item du panier
DELETE
/api/cart/:itemId
Supprimer un item du panier

Fichiers
routes/favorites.js


controllers/favoriteController.js


routes/cart.js


controllers/cartController.js



1.5 Commandes & Paiement
Méthode
URL
Description
POST
/api/orders
Créer une commande (panier, adresse, méthode de paiement…)
GET
/api/orders
Lister ses commandes
GET
/api/orders/:id
Détail d’une commande (produits, statut, historique)
PUT
/api/orders/:id/cancel
Annuler une commande (si possible)
POST
/api/payments
Initier un paiement (Stripe/PayPal…)
GET
/api/payments/:orderId
Vérifier le statut du paiement

Fichiers
routes/orders.js


controllers/orderController.js


routes/payments.js


controllers/paymentController.js



1.6 Notifications push & in-app
Méthode
URL
Description
GET
/api/notifications
Récupérer ses notifications (nouveautés, promos…)
POST
/api/notifications/register
Enregistrer le device token pour push
DELETE
/api/notifications/:id
Marquer comme lue / supprimer une notification

Fichiers
routes/notifications.js


controllers/notificationController.js



2. Routes pour la page admin (React)
Préfixe /api/admin, accès via middleware rôle vendeur (middleware/isVendor.js).
2.1 Produits
Méthode
URL
Description
GET
/api/admin/products
Lister tous les produits du vendeur
GET
/api/admin/products/:id
Détail d’un produit
POST
/api/admin/products
Créer un nouveau produit ({ nom, prix, qté, ... })
PUT
/api/admin/products/:id
Mettre à jour un produit
DELETE
/api/admin/products/:id
Supprimer / archiver un produit


2.2 Variantes (Tailles & Couleurs)
Méthode
URL
Description
POST
/api/admin/products/:id/heights
Ajouter une taille ({ taille })
DELETE
/api/admin/products/:id/heights/:hid
Supprimer une taille
POST
/api/admin/products/:id/colors
Ajouter une couleur ({ couleur })
DELETE
/api/admin/products/:id/colors/:cid
Supprimer une couleur


2.3 Commandes reçues
Méthode
URL
Description
GET
/api/admin/orders
Lister toutes les commandes reçues
GET
/api/admin/orders/:id
Détail d’une commande (client, articles, montant…)
PUT
/api/admin/orders/:id/status
Mettre à jour le statut ({ status: 'Expédiée' })


2.4 Statistiques & Dashboard
Méthode
URL
Description
GET
/api/admin/dashboard/sales
Chiffre d’affaires global, ventes par jour/mois
GET
/api/admin/dashboard/top-products
Top 10 des produits vendus

Fichiers
routes/admin/products.js


controllers/adminProductController.js


routes/admin/orders.js


controllers/adminOrderController.js


routes/admin/dashboard.js


controllers/dashboardController.js


middleware/isVendor.js
