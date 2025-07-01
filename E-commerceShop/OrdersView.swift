import SwiftUI

struct OrdersView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if orderViewModel.isLoading {
                    ProgressView("Chargement des commandes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = orderViewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Erreur")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Réessayer") {
                            orderViewModel.fetchOrders()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if orderViewModel.orders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bag")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("Aucune commande")
                            .font(.headline)
                        
                        Text("Vous n'avez pas encore passé de commande")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(orderViewModel.orders, id: \.id) { order in
                            OrderRowView(order: order, orderViewModel: orderViewModel)
                        }
                    }
                    .refreshable {
                        orderViewModel.fetchOrders()
                    }
                }
            }
            .navigationTitle("Mes commandes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                orderViewModel.fetchOrders()
            }
        }
    }
}

struct OrderRowView: View {
    let order: Order
    let orderViewModel: OrderViewModel
    
    var body: some View {
        NavigationLink(destination: OrderDetailView(order: order)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(orderViewModel.getOrderNumber(order))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(orderViewModel.getOrderItemsCount(order)) article\(orderViewModel.getOrderItemsCount(order) > 1 ? "s" : "") · \(orderViewModel.getOrderTotal(order))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let createdAt = order.created_at {
                        Text(formatDate(createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(orderViewModel.getOrderStatusText(order.status))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(orderViewModel.getOrderStatusColor(order.status).opacity(0.2))
                    .foregroundColor(orderViewModel.getOrderStatusColor(order.status))
                    .cornerRadius(6)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct OrderDetailView: View {
    let order: Order
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // En-tête de la commande
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commande #\(String(order.id.prefix(8)).uppercased())")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let status = order.status {
                        HStack {
                            Text("Statut:")
                                .fontWeight(.medium)
                            Text(status.capitalized)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                    
                    if let createdAt = order.created_at {
                        Text("Passée le: \(formatDate(createdAt))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Articles de la commande
                if let orderVariants = order.order_variants, !orderVariants.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Articles")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(orderVariants, id: \.order_id) { variant in
                            OrderItemRow(variant: variant)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Informations de livraison
                if let adresse = order.adresse_livraison {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adresse de livraison")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(adresse)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Total
                if let total = order.prix_total {
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.2f €", total))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Détails de la commande")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .full
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct OrderItemRow: View {
    let variant: OrderVariant
    
    var body: some View {
        HStack(spacing: 12) {
            // Image du produit
            if let imageUrlString = variant.product_variant?.products?.images?.first,
               let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.product_variant?.products?.nom ?? "Produit indisponible")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let size = variant.product_variant?.heights?.nom,
                   let color = variant.product_variant?.colors?.nom {
                    Text("Taille: \(size), Couleur: \(color)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Quantité: \(variant.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2f €", variant.unit_price))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct OrdersView_Previews: PreviewProvider {
    static var previews: some View {
        OrdersView()
    }
}
