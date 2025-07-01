# Guide de Migration : IDs Aléatoires pour les Commandes

## 🎯 Objectif

Remplacer les IDs séquentiels des commandes par des UUIDs aléatoires pour éviter la confusion entre utilisateurs.

**Problème actuel :** Les commandes utilisent des IDs séquentiels (1, 2, 3, etc.) pour tous les utilisateurs, ce qui peut créer de la confusion.

**Solution :** Utiliser des UUIDs aléatoires pour chaque commande.

## 📋 Prérequis

- Accès à votre base de données Supabase
- Sauvegarde de vos données importantes
- Application mobile mise à jour

## 🚀 Étapes de Migration

### Étape 1 : Sauvegarde (Recommandé)

Avant d'appliquer la migration, faites une sauvegarde de votre base de données :

```sql
-- Dans l'interface Supabase SQL Editor
CREATE TABLE orders_backup_manual AS SELECT * FROM orders;
CREATE TABLE order_variants_backup_manual AS SELECT * FROM order_variants;
CREATE TABLE payments_backup_manual AS SELECT * FROM payments;
```

### Étape 2 : Application de la Migration

#### Option A : Via le Script Node.js

```bash
cd /Users/enzoga/Desktop/ecommerceapp-SWIFT/Projet\ ECOMMERCE
node apply-random-order-ids.js
```

#### Option B : Via l'Interface Supabase

1. Ouvrez votre projet Supabase
2. Allez dans "SQL Editor"
3. Copiez et collez le contenu du fichier `migrations/006_random_order_ids.sql`
4. Exécutez le script

#### Option C : Via psql (si vous avez accès direct)

```bash
psql -h [VOTRE_HOST] -U [VOTRE_USER] -d [VOTRE_DB] -f migrations/006_random_order_ids.sql
```

### Étape 3 : Vérification

Après la migration, vérifiez que :

1. La table `orders` a bien un champ `id` de type UUID
2. Les nouvelles commandes génèrent des UUIDs aléatoires
3. L'application mobile fonctionne correctement

```sql
-- Vérifier la structure de la table
\d orders

-- Vérifier qu'une nouvelle commande génère un UUID
INSERT INTO orders (prix_total, user_id) VALUES (10.00, 'test-user-id') RETURNING id;
```

## 📱 Mise à Jour de l'Application Mobile

L'application mobile a été mise à jour pour :

1. **Gérer les UUIDs** : Le modèle `Order` utilise maintenant `String` au lieu de `Int`
2. **Affichage court** : Les numéros de commande affichent les 8 premiers caractères de l'UUID
3. **Compatibilité** : Tous les services ont été mis à jour

### Changements effectués :

- `Models.swift` : `Order.id` et `OrderVariant.order_id` changés de `Int` à `String`
- `OrderViewModel.swift` : `getOrderNumber()` affiche maintenant un ID court
- `OrdersView.swift` : Affichage cohérent dans la vue détaillée

## ⚠️ Points Importants

### Données Existantes

Si vous avez des données existantes importantes :

1. **Les données sont sauvegardées** dans des tables `_backup`
2. **Migration manuelle nécessaire** si vous voulez conserver l'historique
3. **Nouvelles commandes** utiliseront automatiquement les UUIDs

### Migration des Données Existantes (Optionnel)

Si vous voulez migrer vos données existantes :

```sql
-- Exemple de migration (à adapter selon vos besoins)
INSERT INTO orders (id, prix_total, status, user_id, adresse_livraison, methode_paiement, created_at, updated_at)
SELECT 
    gen_random_uuid() as id,
    prix_total,
    status,
    user_id,
    adresse_livraison,
    methode_paiement,
    created_at,
    updated_at
FROM orders_backup;
```

## 🔧 Dépannage

### Erreur : "function gen_random_uuid() does not exist"

```sql
-- Activer l'extension uuid-ossp
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Erreur : "relation does not exist"

Vérifiez que vous êtes connecté à la bonne base de données et que les tables existent.

### Erreur : "permission denied"

Assurez-vous d'avoir les droits d'administration sur votre base de données Supabase.

## ✅ Validation

Après la migration, testez :

1. **Création de commande** : Vérifiez qu'une nouvelle commande génère un UUID
2. **Affichage mobile** : Vérifiez que l'app affiche correctement les numéros de commande
3. **Fonctionnalités** : Testez toutes les fonctionnalités liées aux commandes

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs de migration
2. Consultez les tables de sauvegarde
3. Testez sur un environnement de développement d'abord

## 🎉 Résultat Attendu

Après la migration :

- ✅ Les nouvelles commandes auront des IDs aléatoires
- ✅ Chaque utilisateur verra ses propres numéros de commande
- ✅ Plus de confusion entre les commandes des différents utilisateurs
- ✅ L'application mobile affichera des numéros courts et lisibles

**Exemple d'affichage :**
- Avant : "Commande #3" (peut être confondu avec d'autres utilisateurs)
- Après : "Commande #A1B2C3D4" (unique et lisible) 