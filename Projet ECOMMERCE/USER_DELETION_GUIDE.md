# Guide de Suppression d'Utilisateur

## Vue d'ensemble

La suppression d'un compte utilisateur dans notre application e-commerce supprime **toutes les données liées** à cet utilisateur, garantissant une suppression complète et conforme au RGPD.

## Ce qui est supprimé

### ✅ Données supprimées automatiquement

1. **Profil utilisateur** (`user_profiles`)
   - Nom, prénom, âge, rôle
   - Données de création et modification

2. **Panier** (`cart_items`)
   - Tous les articles dans le panier
   - Quantités et variantes sélectionnées

3. **Favoris** (`favorites`)
   - Tous les produits favoris
   - Liens user-product

4. **Notifications** (`notifications`)
   - Toutes les notifications personnelles
   - Historique des messages

5. **Paiements** (`payments`)
   - Historique des paiements
   - Données Stripe (si disponibles)

6. **Commandes** (`orders`)
   - Toutes les commandes passées
   - Détails des commandes (`order_variants`)

7. **Profil vendeur** (`vendors`)
   - Si l'utilisateur était vendeur
   - Données du magasin

### ⚠️ Données dans `auth.users`

L'utilisateur dans `auth.users` peut rester selon les permissions :
- **Avec permissions admin** : Supprimé automatiquement
- **Sans permissions admin** : Reste dans `auth.users` mais toutes les données liées sont supprimées

## Méthodes de suppression

### Méthode 1 : Suppression Admin (Recommandée)
```javascript
await supabase.auth.admin.deleteUser(userId);
```
- Supprime l'utilisateur dans `auth.users`
- Déclenche automatiquement la suppression en cascade
- Nécessite `SUPABASE_SERVICE_ROLE_KEY`

### Méthode 2 : Suppression Manuelle (Fallback)
Si les permissions admin ne sont pas disponibles, suppression manuelle dans l'ordre :
1. `cart_items`
2. `favorites`
3. `notifications`
4. `payments`
5. `orders`
6. `vendors`
7. `user_profiles`

## Configuration du schéma

### Contraintes de suppression

```sql
-- Suppression en cascade
user_profiles: REFERENCES auth.users(id) ON DELETE CASCADE
cart_items: REFERENCES auth.users(id) ON DELETE CASCADE
favorites: REFERENCES auth.users(id) ON DELETE CASCADE
notifications: REFERENCES auth.users(id) ON DELETE CASCADE

-- Suppression avec NULL
orders: REFERENCES auth.users(id) ON DELETE SET NULL
payments: REFERENCES auth.users(id) ON DELETE SET NULL
vendors: REFERENCES auth.users(id) ON DELETE SET NULL
```

## API Endpoint

### DELETE `/api/users/me`

**Headers requis :**
```
Authorization: Bearer <jwt_token>
```

**Réponse de succès :**
```json
{
  "message": "Compte supprimé avec succès",
  "note": "Toutes vos données (profil, panier, favoris, commandes) ont été supprimées. Vous devrez vous réinscrire si vous souhaitez utiliser l'application à nouveau."
}
```

**Réponse d'erreur :**
```json
{
  "error": "Message d'erreur détaillé"
}
```

## Test de la suppression

Utilisez le script de test pour vérifier le bon fonctionnement :

```bash
node test-user-deletion.js
```

Ce script :
1. Crée un utilisateur de test
2. Ajoute des données dans toutes les tables
3. Supprime l'utilisateur
4. Vérifie que toutes les données sont supprimées

## Considérations de sécurité

### RGPD Compliance
- ✅ Suppression complète des données personnelles
- ✅ Suppression des données de navigation (panier, favoris)
- ✅ Suppression de l'historique des commandes
- ✅ Suppression des données de paiement

### Sécurité
- ✅ Vérification de l'authentification avant suppression
- ✅ Suppression uniquement de ses propres données
- ✅ Logs des erreurs pour le debugging

## Dépannage

### Erreurs courantes

1. **"User not found"**
   - L'utilisateur a déjà été supprimé
   - Vérifiez l'ID utilisateur

2. **"Permission denied"**
   - Problème avec `SUPABASE_SERVICE_ROLE_KEY`
   - La suppression manuelle sera utilisée

3. **"Foreign key constraint"**
   - Problème d'ordre de suppression
   - Vérifiez les contraintes du schéma

### Vérification post-suppression

```javascript
// Vérifier si l'utilisateur existe encore
const exists = await userService.checkUserExists(userId);

// Vérifier les données restantes
const { data: remainingData } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', userId);
```

## Notes importantes

1. **Irréversible** : La suppression est définitive
2. **Réinscription** : L'utilisateur devra se réinscrire pour utiliser l'app
3. **Email** : L'email peut être réutilisé après suppression
4. **Données anonymes** : Certaines données peuvent rester pour les statistiques

## Support

Pour toute question sur la suppression d'utilisateur, consultez :
- Les logs du serveur
- Le script de test
- La documentation Supabase sur l'authentification 