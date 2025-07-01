# 🔍 Debug du Retour de Paiement Stripe

## Problème
L'app Swift reçoit l'URL de retour de Stripe mais n'affiche pas la page de succès.

## Logs Attendus
Quand un paiement réussit, vous devriez voir ces logs dans la console Xcode :

```
🔗 URL reçue: ecommerceshop://payment/success?session_id=cs_test_...
🔗 URL scheme ecommerceshop détectée
🔗 Analyse détaillée de l'URL:
   Scheme: ecommerceshop
   Host: nil
   Path: '/success'
   Query items: [session_id=cs_test_...]
   URL complète: ecommerceshop://payment/success?session_id=cs_test_...
   Contient session_id: true
✅ Paiement réussi détecté (présence de session_id), session ID: cs_test_...
🔗 Résultat du paiement: success(sessionId: Optional("cs_test_..."))
✅ Paiement réussi, session ID: cs_test_...
```

## Étapes de Debug

### 1. Vérifier les Logs Xcode
- Ouvrez Xcode
- Allez dans la console (View > Debug Area > Activate Console)
- Filtrez par votre app
- Effectuez un paiement et regardez les logs

### 2. Vérifier la Configuration URL Scheme
Dans `Info.plist`, vérifiez que vous avez :
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

### 3. Vérifier la Gestion dans l'App
Dans `E_commerceShopApp.swift`, vérifiez :
```swift
.onOpenURL { url in
    urlSchemeHandler.handleURL(url)
}
```

### 4. Test Manuel de l'URL Scheme
Vous pouvez tester manuellement en tapant dans Safari :
```
ecommerceshop://payment/success?session_id=test123
```

### 5. Vérifier les Notifications
Assurez-vous que `PaymentViewModel` écoute bien les notifications :
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleStripeReturn(_:)),
    name: Foundation.Notification.Name.stripeReturn,
    object: nil
)
```

## Solutions Possibles

### Solution 1: Redémarrage de l'App
Parfois, les URL schemes ne se mettent à jour qu'après un redémarrage complet :
1. Arrêtez complètement l'app sur l'iPhone
2. Relancez depuis Xcode

### Solution 2: Vérifier le Build
Assurez-vous que vous build sur l'appareil et non le simulateur :
- Sélectionnez votre iPhone dans Xcode
- Appuyez sur Cmd+R pour relancer

### Solution 3: Debug Step by Step
Ajoutez des breakpoints dans :
- `URLSchemeHandler.handleURL`
- `PaymentViewModel.handleStripeReturn`
- `CheckoutView.onReceive`

## Logs de Debug Ajoutés

Le code a été amélioré avec plus de logs :
- Analyse détaillée de l'URL
- Vérification de la présence du session_id
- Logs pour chaque étape du parsing

## Test Rapide

Pour tester rapidement, vous pouvez temporairement forcer le succès dans `PaymentViewModel` :

```swift
// Dans handleStripeReturn, ajoutez temporairement :
if let url = notification.userInfo?["url"] as? URL {
    print("🔗 URL reçue: \(url)")
    // Force success pour test
    paymentStatus = .success
    return
}
```

## Contact
Si le problème persiste, partagez les logs complets de la console Xcode. 