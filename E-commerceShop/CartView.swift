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
                        ForEach(cartManager.cartItems) { item in
                            CartItemRow(item: item)
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
    let item: CartItem
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        HStack {
            // Product Image
            if let imageUrlString = item.product?.imageName, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }

            VStack(alignment: .leading) {
                Text(item.product?.name ?? "Produit inconnu")
                    .font(.headline)
                
                let sizeName = item.variant?.height?.nom ?? "N/A"
                let colorName = item.variant?.color?.nom ?? "N/A"
                Text("Taille: \(sizeName), Couleur: \(colorName)")
                    .font(.caption)
                
                let price = item.variant?.prix ?? item.product?.prix_base ?? 0.0
                Text(String(format: "%.2f €", price))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Button("-") {
                    cartManager.decreaseQuantity(for: item)
                }
                Text("\(item.quantity)")
                Button("+") {
                    cartManager.increaseQuantity(for: item)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(CartManager())
    }
}
