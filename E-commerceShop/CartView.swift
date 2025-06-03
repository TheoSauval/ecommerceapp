import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        VStack {
            if cartManager.items.isEmpty {
                Spacer()
                Text("Votre panier est vide.")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(cartManager.items) { product in
                        HStack {
                            Image(product.imageName)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text(product.name)
                                Text("€\(String(format: "%.2f", product.prix))")
                            }

                            Spacer()

                            Button(action: {
                                cartManager.remove(product)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Total :")
                        Spacer()
                        Text("€\(String(format: "%.2f", cartManager.totalPrice))")
                    }

                    NavigationLink(destination: CheckoutView()) {
                        Text("Passer la commande")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                }
                .padding()
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Mon Panier")
    }
}
