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
    @Published var currentOrderId: String?
    
    private let paymentService = PaymentService.shared
    private let orderService = OrderService.shared
    private var cancellationTimer: Timer?
    private var timeoutTimer: Timer?
    
    enum PaymentStatus {
        case idle
        case initiating
        case redirecting
        case processing
        case success
        case failed
        case cancelled
    }
    
    init() {
        // Écouter les notifications de retour de Stripe
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStripeReturn(_:)),
            name: Foundation.Notification.Name.stripeReturn,
            object: nil
        )
        
        // Écouter les notifications d'annulation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStripeCancellation(_:)),
            name: Foundation.Notification.Name.stripeCancelled,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Pas besoin d'appeler cancelTimers() dans deinit car les timers sont automatiquement invalidés
    }
    
    /// Initie le processus de paiement pour une commande
    func initiatePayment(for orderId: String) {
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
                    // Démarrer le timer de timeout (15 minutes)
                    self?.startTimeoutTimer()
                    
                case .failure(let error):
                    self?.paymentStatus = .failed
                    self?.errorMessage = "Erreur lors de l'initiation du paiement: \(error.localizedDescription)"
                    // Annuler la commande en cas d'erreur
                    self?.cancelOrderAndRestoreStock()
                }
            }
        }
    }
    
    /// Ouvre l'interface de paiement Stripe
    private func openStripeCheckout(url: String) {
        paymentService.openStripeCheckout(url: url)
    }
    
    /// Démarrer le timer de timeout pour annuler automatiquement
    private func startTimeoutTimer() {
        // Annuler le timer existant s'il y en a un
        timeoutTimer?.invalidate()
        
        // Annuler après 2 minutes (120 secondes)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.paymentStatus != .success {
                    print("⏰ Timeout atteint, annulation automatique de la commande")
                    self.paymentStatus = .cancelled
                    self.errorMessage = "Le paiement a expiré. Votre commande a été annulée automatiquement."
                    self.cancelOrderAndRestoreStock()
                    self.cancelTimers()
                }
            }
        }
    }
    
    /// Annuler la commande et restaurer le stock
    private func cancelOrderAndRestoreStock() {
        guard let orderId = currentOrderId else { return }
        
        print("🔄 Annulation de la commande et restauration du stock: \(orderId)")
        
        orderService.cancelOrder(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    print("✅ Commande annulée et stock restauré avec succès")
                case .failure(let error):
                    print("❌ Erreur lors de l'annulation de la commande: \(error)")
                    // Même en cas d'erreur, on continue car le timeout automatique du backend s'en chargera
                }
            }
        }
    }
    
    /// Annuler manuellement le paiement
    func cancelPayment() {
        print("🚫 Annulation manuelle du paiement")
        paymentStatus = .cancelled
        errorMessage = "Paiement annulé"
        cancelOrderAndRestoreStock()
        cancelTimers()
    }
    
    /// Annuler les timers
    private func cancelTimers() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        cancellationTimer?.invalidate()
        cancellationTimer = nil
    }
    
    /// Vérifie le statut du paiement avec retry
    func checkPaymentStatus(retryCount: Int = 0) {
        guard let orderId = currentOrderId else { 
            print("⚠️ Aucune commande en cours pour vérifier le statut")
            return 
        }
        
        // Vérifier que l'état est cohérent
        if paymentStatus == .success {
            print("✅ Paiement déjà réussi, pas besoin de vérifier")
            return
        }
        
        paymentStatus = .processing
        print("🔄 Vérification du statut du paiement pour la commande: \(orderId)")
        
        paymentService.getStripePaymentStatus(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { 
                    print("⚠️ PaymentViewModel libéré, arrêt de la vérification")
                    return 
                }
                
                // Vérifier que la commande existe toujours
                guard let currentOrderId = self.currentOrderId, currentOrderId == orderId else {
                    print("⚠️ Commande changée ou libérée, arrêt de la vérification")
                    return
                }
                
                switch result {
                case .success(let status):
                    print("📊 Statut reçu du serveur: \(status.status)")
                    // Accepte "succeeded" ou "Payé" (backend)
                    if status.status == "succeeded" || status.status == "Payé" {
                        self.paymentStatus = .success
                        self.errorMessage = nil
                        self.cancelTimers() // Arrêter le timeout
                        print("✅ Paiement confirmé avec succès")
                        // (Le panier sera vidé dans la vue CheckoutView)
                    } else if status.status == "cancelled" || status.status == "Annulée" {
                        self.paymentStatus = .cancelled
                        self.errorMessage = "Le paiement a été annulé"
                        self.cancelTimers()
                        print("❌ Paiement annulé confirmé")
                    } else if retryCount < 3 {
                        // Réessayer après 2 secondes
                        print("🔄 Réessai \(retryCount + 1)/3 dans 2 secondes...")
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                            self.checkPaymentStatus(retryCount: retryCount + 1)
                        }
                    } else {
                        self.paymentStatus = .failed
                        self.errorMessage = "Le paiement n'a pas pu être confirmé. Merci de vérifier votre historique ou de réessayer. (Statut: \(status.status))"
                        self.cancelTimers()
                        print("❌ Échec de la vérification après \(retryCount) tentatives")
                    }
                case .failure(let error):
                    print("❌ Erreur lors de la vérification: \(error)")
                    if retryCount < 3 {
                        print("🔄 Réessai \(retryCount + 1)/3 dans 2 secondes...")
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                            self.checkPaymentStatus(retryCount: retryCount + 1)
                        }
                    } else {
                        self.paymentStatus = .failed
                        self.errorMessage = "Erreur lors de la vérification du statut: \(error.localizedDescription)"
                        self.cancelTimers()
                        print("❌ Échec de la vérification après \(retryCount) tentatives")
                    }
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
        cancelTimers()
    }
    
    /// Nettoie l'état quand l'utilisateur quitte vraiment l'app
    func cleanupOnAppExit() {
        // Si on a une commande en cours et qu'on n'est pas en succès, annuler
        if let orderId = currentOrderId, paymentStatus != .success {
            print("🚪 Utilisateur quitte l'app, annulation de la commande: \(orderId)")
            cancelOrderAndRestoreStock()
        }
        cancelTimers()
    }
    
    /// Restaure l'état du paiement quand l'app revient au premier plan
    func restorePaymentState() {
        // Si on a une commande en cours et qu'on n'est pas en succès, vérifier le statut
        if let orderId = currentOrderId, paymentStatus != .success {
            print("🔄 Restauration de l'état du paiement pour la commande: \(orderId)")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                self.checkPaymentStatus()
            }
        }
    }
    
    /// Gère le retour de l'application Stripe
    func handleAppReturn() {
        // Vérifier le statut du paiement après le retour
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            self.checkPaymentStatus()
        }
    }
    
    /// Gère le retour de Stripe via notification
    @objc func handleStripeReturn(_ notification: Foundation.Notification) {
        Task { @MainActor in
            // Protection contre les appels multiples
            if self.paymentStatus == .success {
                print("⚠️ Paiement déjà réussi, ignorer le retour de Stripe")
                return
            }
            
            if let url = notification.userInfo?["url"] as? URL {
                print("🔗 Retour de Stripe: \(url)")
                
                // Vérifier que la commande existe toujours
                guard let orderId = self.currentOrderId else {
                    print("⚠️ Aucune commande en cours, ignorer le retour de Stripe")
                    return
                }
                
                print("🔄 Traitement du retour de Stripe pour la commande: \(orderId)")
                
                // Analyser le résultat du paiement
                if let result = notification.userInfo?["result"] as? URLSchemeHandler.PaymentResult {
                    switch result {
                    case .success(let sessionId):
                        print("✅ Paiement réussi, session ID: \(sessionId ?? "nil")")
                        self.paymentStatus = .success
                        self.errorMessage = nil
                        self.cancelTimers()
                        
                        // Vérifier le statut du paiement après un délai
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                        self.checkPaymentStatus()
                        
                    case .cancelled:
                        print("❌ Paiement annulé")
                        self.paymentStatus = .cancelled
                        self.errorMessage = "Le paiement a été annulé"
                        self.cancelOrderAndRestoreStock()
                        self.cancelTimers()
                        
                    case .error(let error):
                        print("❌ Erreur de paiement: \(error)")
                        // Même en cas d'erreur de parsing, vérifier le statut du paiement
                        // car le paiement peut avoir réussi côté serveur
                        self.paymentStatus = .processing
                        self.errorMessage = "Vérification du statut du paiement..."
                        
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                        self.checkPaymentStatus()
                    }
                } else {
                    // Fallback si le résultat n'est pas disponible
                    print("⚠️ Résultat de paiement non disponible, vérification du statut...")
                    self.paymentStatus = .processing
                    self.errorMessage = "Vérification du statut du paiement..."
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                    self.checkPaymentStatus()
                }
            }
        }
    }
    
    /// Gère l'annulation de Stripe via notification
    @objc func handleStripeCancellation(_ notification: Foundation.Notification) {
        Task { @MainActor in
            print("🚫 Annulation de Stripe détectée")
            paymentStatus = .cancelled
            errorMessage = "Le paiement a été annulé"
            cancelOrderAndRestoreStock()
            cancelTimers()
        }
    }
}
