# 🔐 Guide de la Fonctionnalité de Changement de Mot de Passe

## 📋 Vue d'ensemble

Cette fonctionnalité permet aux utilisateurs de changer leur mot de passe de manière sécurisée en utilisant Supabase Auth. Elle inclut :

- ✅ **Validation de l'ancien mot de passe** pour la sécurité
- ✅ **Validation du nouveau mot de passe** (longueur, complexité)
- ✅ **Interface utilisateur intuitive** avec indicateur de force
- ✅ **Gestion des erreurs** complète
- ✅ **Intégration Supabase Auth** native

## 🏗️ Architecture

### Backend (Node.js + Supabase)

#### 1. Service d'Authentification (`services/authService.js`)
```javascript
async changePassword(oldPassword, newPassword) {
    // 1. Vérifier l'authentification de l'utilisateur
    // 2. Valider l'ancien mot de passe
    // 3. Mettre à jour avec le nouveau mot de passe
    // 4. Utiliser Supabase Auth pour la sécurité
}
```

#### 2. Contrôleur (`controllers/authController.js`)
```javascript
const changePassword = async (req, res) => {
    // Validation des données
    // Appel au service
    // Gestion des erreurs
}
```

#### 3. Route (`routes/auth.js`)
```javascript
router.put('/change-password', authenticateToken, changePassword);
```

### Frontend (Swift + SwiftUI)

#### 1. Service Utilisateur (`UserService.swift`)
```swift
func changePassword(passwordData: PasswordChange, completion: @escaping (Result<Void, Error>) -> Void)
```

#### 2. Vue de Changement (`ChangePasswordView.swift`)
- Interface utilisateur complète
- Validation en temps réel
- Indicateur de force du mot de passe
- Gestion des erreurs

## 🚀 Utilisation

### Pour l'Utilisateur

1. **Accéder aux paramètres** : Menu → Paramètres
2. **Choisir "Changer le mot de passe"** dans la section Sécurité
3. **Saisir l'ancien mot de passe** pour vérification
4. **Saisir le nouveau mot de passe** avec confirmation
5. **Valider le changement** en cliquant sur le bouton

### Validation du Mot de Passe

Le système vérifie :
- ✅ **Longueur minimale** : 6 caractères
- ✅ **Correspondance** : nouveau mot de passe = confirmation
- ✅ **Différence** : nouveau ≠ ancien mot de passe
- ✅ **Force** : indicateur visuel (faible/moyen/fort)

## 🔧 Configuration

### Variables d'Environnement

Assurez-vous que ces variables sont configurées dans votre `.env` :

```env
# Configuration Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Configuration de l'application
FRONTEND_URL=http://localhost:3001
```

### API Endpoint

```
PUT /api/auth/change-password
Headers: Authorization: Bearer <token>
Body: {
    "oldPassword": "ancien_mot_de_passe",
    "newPassword": "nouveau_mot_de_passe"
}
```

## 🧪 Tests

### Lancer les Tests Automatiques

```bash
cd "Projet ECOMMERCE"
node test-change-password.js
```

### Tests Inclus

1. **Création d'utilisateur de test**
2. **Connexion et obtention du token**
3. **Changement de mot de passe réussi**
4. **Vérification du nouveau mot de passe**
5. **Tests d'erreurs** :
   - Ancien mot de passe incorrect
   - Mot de passe trop court
   - Nouveau mot de passe identique à l'ancien

## 🛡️ Sécurité

### Mesures Implémentées

1. **Authentification requise** : Token JWT obligatoire
2. **Validation de l'ancien mot de passe** : Vérification avant changement
3. **Validation du nouveau mot de passe** : Règles de complexité
4. **Utilisation de Supabase Auth** : Sécurité native
5. **Gestion des erreurs** : Messages d'erreur sécurisés

### Bonnes Pratiques

- ✅ **Ne jamais stocker** les mots de passe en clair
- ✅ **Utiliser HTTPS** en production
- ✅ **Valider côté serveur** toutes les entrées
- ✅ **Limiter les tentatives** de changement
- ✅ **Logger les changements** pour audit

## 🔍 Dépannage

### Erreurs Courantes

#### "Ancien mot de passe incorrect"
- Vérifiez que l'utilisateur saisit le bon mot de passe actuel
- Assurez-vous que la session est valide

#### "Mot de passe trop court"
- Le nouveau mot de passe doit contenir au moins 6 caractères
- Encouragez l'utilisateur à utiliser un mot de passe plus fort

#### "Erreur de serveur"
- Vérifiez la connexion à Supabase
- Consultez les logs du serveur
- Vérifiez les variables d'environnement

### Logs de Debug

Activez les logs détaillés dans votre application :

```javascript
// Dans authService.js
console.log('🔐 Tentative de changement de mot de passe pour:', user.email);
console.log('✅ Mot de passe changé avec succès');
```

## 📱 Interface Utilisateur

### Fonctionnalités de l'UI

1. **Champs sécurisés** avec option d'affichage/masquage
2. **Validation en temps réel** avec messages d'erreur
3. **Indicateur de force** du mot de passe
4. **Bouton désactivé** tant que le formulaire n'est pas valide
5. **Messages de succès** après changement réussi
6. **Gestion des états de chargement**

### Composants SwiftUI

- `ChangePasswordView` : Vue principale
- `PasswordStrengthView` : Indicateur de force
- `PasswordStrength` : Énumération des niveaux

## 🔄 Intégration avec Supabase

### Avantages de Supabase Auth

1. **Sécurité native** : Gestion automatique des hachages
2. **Sessions sécurisées** : Tokens JWT automatiques
3. **Audit intégré** : Logs des changements de mot de passe
4. **Conformité** : Respect des standards de sécurité
5. **Scalabilité** : Infrastructure cloud gérée

### Workflow Supabase

1. **Vérification de l'utilisateur** : `supabase.auth.getUser()`
2. **Validation de l'ancien mot de passe** : `supabase.auth.signInWithPassword()`
3. **Mise à jour du mot de passe** : `supabase.auth.updateUser()`

## 🎯 Prochaines Étapes

### Améliorations Possibles

1. **Authentification à deux facteurs** (2FA)
2. **Historique des changements** de mot de passe
3. **Notifications par email** lors du changement
4. **Politique de complexité** plus stricte
5. **Expiration automatique** des mots de passe

### Monitoring

- Surveillez les tentatives de changement de mot de passe
- Alertez en cas de changements suspects
- Analysez les patterns d'utilisation

## 📞 Support

En cas de problème :

1. **Vérifiez les logs** du serveur et de Supabase
2. **Testez l'API** avec le script de test fourni
3. **Consultez la documentation** Supabase
4. **Vérifiez la configuration** des variables d'environnement

---

**🎉 Votre fonctionnalité de changement de mot de passe est maintenant opérationnelle et sécurisée !** 