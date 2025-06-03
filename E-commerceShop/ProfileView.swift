import SwiftUI

struct ProfileView: View {
    var onLogout: () -> Void

    @State private var selectedItem: ProfileItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 80, height: 80)

                            Text("TS")
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        Text("Bonjour Théo")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 32)

                    SectionView(title: "COMPTE", items: [
                        .init(title: "Mes commandes", icon: "bag"),
                        .init(title: "Mes coordonnées", icon: "person"),
                        .init(title: "Carnet d'adresses", icon: "book"),
                        .init(title: "Paramètres", icon: "gear")
                    ]) { item in
                        selectedItem = item
                    }

                    SectionView(title: "AIDE", items: [
                        .init(title: "Assistance client", icon: "questionmark.circle")
                    ]) { item in
                        selectedItem = item
                    }

                    SectionView(title: "AUTRES", items: [
                        .init(title: "Social", icon: "person.2")
                    ]) { item in
                        selectedItem = item
                    }

                    Button(action: {
                        onLogout()
                    }) {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedItem) { item in
                destinationView(for: item)
            }
        }
    }

    @ViewBuilder
    func destinationView(for item: ProfileItem) -> some View {
        switch item.title {
        case "Mes commandes":
            OrdersView()
        case "Mes coordonnées":
            PersonalInfoView()
        case "Carnet d'adresses":
            AddressesView()
        case "Paramètres":
            SettingsView()
        case "Assistance client":
            SupportView()
        case "Social":
            SocialLinksView()
        default:
            EmptyView()
        }
    }
}

// MARK: - Reusable views

struct SectionView: View {
    let title: String
    let items: [ProfileItem]
    var onItemTap: ((ProfileItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    Button(action: {
                        onItemTap?(item)
                    }) {
                        HStack {
                            Image(systemName: item.icon)
                                .frame(width: 24)
                                .foregroundColor(.black)

                            Text(item.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct ProfileItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
}
