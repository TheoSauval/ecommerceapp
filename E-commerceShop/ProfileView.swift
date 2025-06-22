import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Mon Compte")) {
                    NavigationLink(destination: AccountView()) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Informations Personnelles")
                        }
                    }
                    NavigationLink(destination: OrdersView()) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                            Text("Mes Commandes")
                        }
                    }
                }

                Section(header: Text("Paramètres")) {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Paramètres")
                        }
                    }
                    NavigationLink(destination: SupportView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Support")
                        }
                    }
                }

                Section {
                    Button(action: {
                        authService.logout()
                    }) {
                        Text("Déconnexion")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Profil")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthService.shared)
    }
}
