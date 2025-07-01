import Foundation
import SwiftUI

class URLSchemeHandler: ObservableObject {
    static let shared = URLSchemeHandler()
    @Published var shouldCheckPaymentStatus = false
    @Published var paymentResult: PaymentResult?
    
    private init() {}
    
    enum PaymentResult {
        case success(sessionId: String?)
        case cancelled
        case error(String)
    }
    
    func handleURL(_ url: URL) {
        print("🔗 URL reçue: \(url.absoluteString)")
        
        // Vérifier si c'est un retour de Stripe via le schéma personnalisé
        if url.scheme == "ecommerceshop" {
            print("🔗 URL scheme ecommerceshop détectée")
            
            // Analyser l'URL pour déterminer le résultat
            let result = parsePaymentResult(from: url)
            self.paymentResult = result
            self.shouldCheckPaymentStatus = true
            
            // Notifier que l'utilisateur est revenu de Stripe
            NotificationCenter.default.post(
                name: Foundation.Notification.Name.stripeReturn,
                object: nil,
                userInfo: ["url": url, "result": result]
            )
            
            print("🔗 Résultat du paiement: \(result)")
        }
    }
    
    private func parsePaymentResult(from url: URL) -> PaymentResult {
        let path = url.path
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let urlString = url.absoluteString
        
        print("🔗 Analyse détaillée de l'URL:")
        print("   Scheme: \(url.scheme ?? "nil")")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: '\(path)'")
        print("   Query items: \(queryItems)")
        print("   URL complète: \(urlString)")
        
        // Vérifier si l'URL contient un session_id (indicateur de succès)
        let hasSessionId = queryItems.first(where: { $0.name == "session_id" }) != nil
        print("   Contient session_id: \(hasSessionId)")
        
        // Logique de parsing améliorée
        if hasSessionId {
            let sessionId = queryItems.first(where: { $0.name == "session_id" })?.value
            print("✅ Paiement réussi détecté (présence de session_id), session ID: \(sessionId ?? "nil")")
            return .success(sessionId: sessionId)
        }
        
        // Vérifier les mots-clés dans l'URL
        let urlStringLower = urlString.lowercased()
        let pathLower = path.lowercased()
        
        if urlStringLower.contains("success") || pathLower.contains("success") {
            let sessionId = queryItems.first(where: { $0.name == "session_id" })?.value
            print("✅ Paiement réussi détecté (mot-clé 'success'), session ID: \(sessionId ?? "nil")")
            return .success(sessionId: sessionId)
        } 
        else if urlStringLower.contains("cancel") || pathLower.contains("cancel") {
            print("❌ Paiement annulé détecté (mot-clé 'cancel')")
            return .cancelled
        }
        else {
            print("❌ URL de retour inconnue: \(urlString)")
            print("   Path: '\(path)'")
            print("   Query items: \(queryItems)")
            return .error("URL de retour inconnue: \(urlString)")
        }
    }
    
    func resetPaymentResult() {
        paymentResult = nil
        shouldCheckPaymentStatus = false
    }
}

// MARK: - Extension globale pour Notification.Name (Foundation)
extension Foundation.Notification.Name {
    static let stripeReturn = Foundation.Notification.Name("stripeReturn")
}
