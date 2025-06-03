import SwiftUI

struct TestTabsWithNav: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Accueil")
                .tag(0)
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }

            NavigationStack {
                VStack(spacing: 20) {
                    Text("Bienvenue sur le profil")
                        .font(.title)

                    NavigationLink(destination: RegisterView()) {
                        Text("S'inscrire")
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal, 32)
                    }
                }
                .navigationTitle("Profil")
            }
            .tag(1)
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
        }
    }
}

#Preview {
    TestTabsWithNav()
}
