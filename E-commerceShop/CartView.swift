import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        NavigationView {
            VStack {
                if cartManager.cartItems.isEmpty {
                    Text("Votre panier est vide")
                        .font(.title)
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(cartManager.cartItems, id: \.id) { item in
                            CartItemRow(itemId: item.id)
                        }
                        .onDelete(perform: deleteItems)
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f €", cartManager.totalPrice))
                                .font(.headline)
                        }
                        
                        NavigationLink(destination: CheckoutView()) {
                            Text("Passer la commande")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Panier")
            .onAppear {
                cartManager.fetchCart()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { cartManager.cartItems[$0] }
        for item in itemsToDelete {
            cartManager.removeFromCart(cartItemId: item.id)
        }
    }
}

struct CartItemRow: View {
    let itemId: Int
    @EnvironmentObject var cartManager: CartManager
    @State private var selectedQuantity: Int = 1

    var body: some View {
        if let item = cartManager.cartItems.first(where: { $0.id == itemId }) {
            HStack(alignment: .center, spacing: 16) {
                // Product Image
                if let imageUrlString = item.product_variant?.products?.images?.first, let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product_variant?.products?.nom ?? "Produit indisponible")
                        .font(.headline)
                    let sizeName = item.product_variant?.heights?.nom ?? "N/A"
                    let colorName = item.product_variant?.colors?.nom ?? "N/A"
                    Text("Taille: \(sizeName), Couleur: \(colorName)")
                        .font(.caption)
                    let price = item.product_variant?.prix ?? item.product_variant?.products?.prix_base ?? 0.0
                    Text(String(format: "%.2f €", price))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Sélecteur de quantité amélioré
                VStack(alignment: .trailing, spacing: 4) {
                    // Sélecteur de quantité stylisé
                    Menu {
                        ForEach(1...max(1, item.product_variant?.stock ?? 1), id: \.self) { quantity in
                            Button(action: {
                                selectedQuantity = quantity
                                if quantity != item.quantity {
                                    cartManager.updateQuantity(cartItemId: item.id, newQuantity: quantity)
                                }
                            }) {
                                HStack {
                                    Text("\(quantity)")
                                    if quantity == selectedQuantity {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(selectedQuantity)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(minWidth: 25)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .onAppear {
                        selectedQuantity = item.quantity
                    }
                    
                    // Affichage du stock disponible
                    if let stock = item.product_variant?.stock {
                        Text("Stock: \(stock)")
                            .font(.caption2)
                            .foregroundColor(stock < 5 ? .orange : .secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture { /* Désactive le tap sur toute la ligne */ }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(CartManager())
    }
}
