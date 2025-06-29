//
//  PaymentViewModel.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentStatus: PaymentStatus = .idle
    @Published var currentOrderId: Int?
    
    private let paymentService = PaymentService.shared
    private let orderService = OrderService.shared
    
    enum PaymentStatus {
        case idle
        case initiating
        case redirecting
        case processing
        case success
        case failed
    }
    
    init() {
        // Écouter les notifications de retour de Stripe
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStripeReturn(_:)),
            name: Foundation.Notification.Name.stripeReturn,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Initie le processus de paiement pour une commande
    func initiatePayment(for orderId: Int) {
        guard !isLoading else { return }
        
        isLoading = true
        paymentStatus = .initiating
        errorMessage = nil
        currentOrderId = orderId
        
        // Configurer le token d'authentification
        if let token = AuthService.shared.getAccessToken() {
            paymentService.setAuthToken(token)
        }
        
        paymentService.initiateStripePayment(orderId: orderId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.paymentStatus = .redirecting
                    self?.openStripeCheckout(url: response.url)
                    
                case .failure(let error):
                    self?.paymentStatus = .failed
                    self?.errorMessage = "Erreur lors de l'initiation du paiement: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Ouvre l'interface de paiement Stripe
    private func openStripeCheckout(url: String) {
        paymentService.openStripeCheckout(url: url)
    }
    
    /// Vérifie le statut du paiement
    func checkPaymentStatus() {
        guard let orderId = currentOrderId else { return }
        
        paymentStatus = .processing
        
        paymentService.getStripePaymentStatus(orderId: orderId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    switch status.status {
                    case "succeeded":
                        self?.paymentStatus = .success
                    case "requires_payment_method", "requires_confirmation", "requires_action":
                        self?.paymentStatus = .processing
                    case "canceled", "failed":
                        self?.paymentStatus = .failed
                        self?.errorMessage = "Le paiement a échoué"
                    default:
                        self?.paymentStatus = .processing
                    }
                    
                case .failure(let error):
                    self?.paymentStatus = .failed
                    self?.errorMessage = "Erreur lors de la vérification du statut: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Réinitialise l'état du paiement
    func resetPaymentState() {
        isLoading = false
        errorMessage = nil
        paymentStatus = .idle
        currentOrderId = nil
    }
    
    /// Gère le retour de l'application Stripe
    func handleAppReturn() {
        // Vérifier le statut du paiement après le retour
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkPaymentStatus()
        }
    }
    
    /// Gère le retour de Stripe via notification
    @objc func handleStripeReturn(_ notification: Foundation.Notification) {
        if let url = notification.userInfo?["url"] as? URL {
            print("🔗 Retour de Stripe: \(url)")
            
            // Analyser le résultat du paiement
            if let result = notification.userInfo?["result"] as? URLSchemeHandler.PaymentResult {
                switch result {
                case .success(let sessionId):
                    print("✅ Paiement réussi, session ID: \(sessionId ?? "nil")")
                    paymentStatus = .success
                    
                    // Vérifier le statut du paiement après un délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.checkPaymentStatus()
                    }
                    
                case .cancelled:
                    print("❌ Paiement annulé")
                    paymentStatus = .failed
                    errorMessage = "Le paiement a été annulé"
                    
                case .error(let error):
                    print("❌ Erreur de paiement: \(error)")
                    paymentStatus = .failed
                    errorMessage = "Erreur lors du paiement: \(error)"
                }
            } else {
                // Fallback si le résultat n'est pas disponible
                print("⚠️ Résultat de paiement non disponible, vérification du statut...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.checkPaymentStatus()
                }
            }
        }
    }
}
