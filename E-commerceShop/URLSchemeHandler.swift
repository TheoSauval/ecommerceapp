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
        
        print("🔗 Path: \(path)")
        print("🔗 Query items: \(queryItems)")
        
        if path.contains("/payment/success") {
            let sessionId = queryItems.first(where: { $0.name == "session_id" })?.value
            return .success(sessionId: sessionId)
        } else if path.contains("/payment/cancel") {
            return .cancelled
        } else {
            return .error("URL de retour inconnue")
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
