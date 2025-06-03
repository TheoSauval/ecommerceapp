import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedCategoryFilter: CategoryFilter = .all
    @Binding var favoriteProducts: [Product]
    @Binding var selectedTab: Int
    @EnvironmentObject var cartManager: CartManager

    var filteredProducts: [Product] {
        allProducts.filter { product in
            (selectedCategoryFilter == .all || product.category == selectedCategoryFilter)
            && (searchText.isEmpty || product.name.lowercased().contains(searchText.lowercased()))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 👋 Bienvenue
                Text("Bienvenue 👋")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 🔥 Prénom
                Text("Theo")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 🔎 Barre de recherche
                SearchBar(placeholder: "Rechercher un produit...", text: $searchText)
                    .padding(10)

                // 📂 Filtres
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CategoryFilter.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategoryFilter = category
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: iconName(for: category))
                                        .font(.system(size: 14))
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    selectedCategoryFilter == category ? Color.black : Color.white
                                )
                                .foregroundColor(
                                    selectedCategoryFilter == category ? .white : .black
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: selectedCategoryFilter == category ? 0 : 1)
                                )
                                .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                // 🛍️ Produits
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredProducts) { product in
                            ProductCardView(
                                product: product,
                                favoriteProducts: $favoriteProducts,
                                selectedTab: $selectedTab
                            )
                            .environmentObject(cartManager)
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
            }
        }
    }

    func iconName(for category: CategoryFilter) -> String {
        switch category {
        case .all:
            return "square.grid.2x2.fill"
        case .manteau:
            return "cloud.fill"
        case .tshirt:
            return "tshirt.fill"
        case .sweat:
            return "hoodie"
        }
    }
}
