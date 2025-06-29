//
//  OrderConfirmationView.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec icône de succès
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.green)
                        
                        Text("Commande confirmée !")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Votre commande #\(order.id) a été traitée avec succès.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Détails de la commande
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Détails de la commande")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Numéro de commande:")
                                Spacer()
                                Text("#\(order.id)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Date:")
                                Spacer()
                                Text(formatDate(order.created_at ?? ""))
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Total:")
                                Spacer()
                                Text(String(format: "%.2f €", order.prix_total ?? 0.0))
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Statut:")
                                Spacer()
                                Text(order.status ?? "-")
                                    .fontWeight(.medium)
                                    .foregroundColor(statusColor(order.status ?? "-"))
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Adresse de livraison
                    if let adresse = order.adresse_livraison {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Adresse de livraison")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(adresse)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Produits commandés
                    if let orderVariants = order.order_variants {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Produits commandés")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            ForEach(orderVariants, id: \.order_id) { variant in
                                OrderItemRow(variant: variant)
                            }
                        }
                    }
                    
                    // Informations supplémentaires
                    VStack(spacing: 12) {
                        Text("Prochaines étapes")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(icon: "envelope", text: "Un email de confirmation vous a été envoyé")
                            InfoRow(icon: "truck", text: "Vous recevrez un email de suivi de livraison")
                            InfoRow(icon: "clock", text: "Livraison estimée sous 3-5 jours ouvrés")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Boutons d'action
                    VStack(spacing: 12) {
                        Button("Voir mes commandes") {
                            // Navigation vers les commandes
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Retour à l'accueil") {
                            // Vider le panier et retourner à l'accueil
                            cartManager.clearCart()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "payé", "confirmed":
            return .green
        case "en attente", "pending":
            return .orange
        case "annulé", "cancelled":
            return .red
        default:
            return .primary
        }
    }
}

struct OrderItemRow: View {
    let variant: OrderVariant
    
    var body: some View {
        HStack {
            // Image du produit (placeholder)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.product_variant?.product?.nom ?? "Produit inconnu")
                    .font(.headline)
                
                if let color = variant.product_variant?.color?.nom,
                   let size = variant.product_variant?.height?.nom {
                    Text("\(color) - \(size)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Quantité: \(variant.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2f €", variant.unit_price))
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
        }
    }
} 
