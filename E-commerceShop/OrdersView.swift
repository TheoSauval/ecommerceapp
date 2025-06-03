import SwiftUI

struct OrdersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Mes commandes")
                .font(.largeTitle)
                .fontWeight(.bold)

            List {
                Section(header: Text("Récemment")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Commande #1234")
                                .fontWeight(.semibold)
                            Text("2 articles · 59,98 €")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Livré")
                            .foregroundColor(.green)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Commande #1233")
                                .fontWeight(.semibold)
                            Text("1 article · 29,99 €")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("En cours")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Mes commandes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
