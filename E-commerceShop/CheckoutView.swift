//
//  CheckoutView.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/05/2025.
//

import SwiftUI

struct CheckoutView: View {
    @StateObject private var paymentViewModel = PaymentViewModel()
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @Environment(\.presentationMode) var presentationMode
    @State private var confirmedOrder: Order?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                switch paymentViewModel.paymentStatus {
                case .idle:
                    idleView
                case .initiating:
                    initiatingView
                case .redirecting:
                    redirectingView
                case .processing:
                    processingView
                case .success:
                    successView
                case .failed:
                    failedView
                }
            }
            .padding()
            .navigationTitle("Paiement")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Réinitialiser l'état si nécessaire
                if paymentViewModel.paymentStatus == .idle {
                    paymentViewModel.resetPaymentState()
                }
            }
            .onReceive(urlSchemeHandler.$shouldCheckPaymentStatus) { shouldCheck in
                if shouldCheck {
                    print("🔗 Vérification du statut de paiement déclenchée")
                    paymentViewModel.handleAppReturn()
                    urlSchemeHandler.resetPaymentResult()
                }
            }
            .sheet(isPresented: $showConfirmation) {
                if let order = confirmedOrder {
                    OrderConfirmationView(order: order)
                }
            }
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .resizable()
                .frame(width: 80, height: 60)
                .foregroundStyle(.blue)
            
            Text("Préparation du paiement")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Total: \(String(format: "%.2f €", cartManager.totalPrice))")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("Procéder au paiement") {
                initiatePayment()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var initiatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initialisation du paiement...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Veuillez patienter pendant que nous préparons votre paiement.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var redirectingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.right.square")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.blue)
            
            Text("Redirection vers Stripe")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Vous allez être redirigé vers l'interface de paiement sécurisée de Stripe.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(1.2)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Traitement du paiement...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Veuillez patienter pendant que nous traitons votre paiement.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.green)
            
            Text("Paiement réussi !")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Votre commande a été traitée avec succès.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Continuer") {
                // Vider le panier et retourner à l'accueil
                cartManager.clearCart()
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var failedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.red)
            
            Text("Paiement échoué")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let errorMessage = paymentViewModel.errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button("Réessayer") {
                    paymentViewModel.resetPaymentState()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
    }
    
    private func initiatePayment() {
        // Créer une commande d'abord
        createOrder { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let orderId):
                    self.paymentViewModel.initiatePayment(for: orderId)
                case .failure(let error):
                    self.paymentViewModel.errorMessage = "Erreur lors de la création de la commande: \(error.localizedDescription)"
                    self.paymentViewModel.paymentStatus = .failed
                }
            }
        }
    }
    
    private func createOrder(completion: @escaping (Result<Int, Error>) -> Void) {
        // Vérification du stock avant de créer la commande
        let outOfStockItems = cartManager.cartItems.filter { ($0.product_variant?.stock ?? 0) < $0.quantity }
        if !outOfStockItems.isEmpty {
            completion(.failure(NSError(domain: "StockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Un ou plusieurs articles de votre panier ne sont plus en stock. Veuillez les retirer avant de commander."])))
            return
        }
        
        // Créer la commande à partir du panier
        print("Cart items:", cartManager.cartItems)
        let orderRequest = createOrderRequest()
        
        OrderService.shared.createOrder(orderData: orderRequest) { result in
            switch result {
            case .success(let order):
                print("✅ Commande créée avec succès: ID \(order.id)")
                completion(.success(order.id))
            case .failure(let error):
                print("❌ Erreur lors de la création de la commande: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func createOrderRequest() -> OrderRequestBackend {
        let items = cartManager.cartItems.map { item in
            OrderItemBackend(
                productId: item.product_variant?.product_id ?? 0,
                variantId: item.variant_id,
                quantity: item.quantity
            )
        }
        print("Items envoyés au backend:", items)
        return OrderRequestBackend(
            items: items,
            adresse_livraison: "Adresse par défaut", // À améliorer avec un formulaire
            methode_paiement: "Stripe"
        )
    }
}
