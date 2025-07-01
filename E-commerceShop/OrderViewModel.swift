//
//  OrderViewModel.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation
import SwiftUI

class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let orderService = OrderService.shared
    
    func fetchOrders() {
        isLoading = true
        errorMessage = nil
        
        orderService.getOrders { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let orders):
                    self?.orders = orders.sorted { order1, order2 in
                        // Trier par date de création (plus récent en premier)
                        let date1 = order1.created_at ?? ""
                        let date2 = order2.created_at ?? ""
                        return date1 > date2
                    }
                case .failure(let error):
                    self?.errorMessage = "Erreur de chargement des commandes: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func getOrderStatusColor(_ status: String?) -> Color {
        guard let status = status else { return .gray }
        
        switch status.lowercased() {
        case "en_attente":
            return .orange
        case "en_cours":
            return .blue
        case "livré":
            return .green
        case "annulé":
            return .red
        default:
            return .gray
        }
    }
    
    func getOrderStatusText(_ status: String?) -> String {
        guard let status = status else { return "Inconnu" }
        
        switch status.lowercased() {
        case "en_attente":
            return "En attente"
        case "en_cours":
            return "En cours"
        case "livré":
            return "Livré"
        case "annulé":
            return "Annulé"
        default:
            return status.capitalized
        }
    }
    
    func getOrderItemsCount(_ order: Order) -> Int {
        return order.order_variants?.count ?? 0
    }
    
    func getOrderTotal(_ order: Order) -> String {
        let total = order.prix_total ?? 0.0
        return String(format: "%.2f €", total)
    }
    
    func getOrderNumber(_ order: Order) -> String {
        // Utiliser les 8 premiers caractères de l'UUID pour un affichage plus court
        let shortId = String(order.id.prefix(8)).uppercased()
        return "Commande #\(shortId)"
    }
} 