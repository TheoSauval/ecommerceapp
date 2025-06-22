import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var showingDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text("Préférences")) {
                Toggle("Notifications", isOn: $notificationsEnabled)
                Toggle("Mode sombre", isOn: $darkModeEnabled)
            }

            Section(header: Text("Sécurité")) {
                NavigationLink("Changer le mot de passe") {
                    Text("Fonctionnalité à venir...")
                }
            }

            Section(header: Text("Gestion du compte")) {
                Button("Supprimer mon compte") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Paramètres")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Supprimer le compte", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                userService.deleteAccount { result in
                    switch result {
                    case .success:
                        // La déconnexion est gérée par le changement d'état d'authentification
                        authService.logout()
                    case .failure(let error):
                        // Gérer l'erreur, par exemple afficher une autre alerte
                        print("Erreur de suppression: \\(error.localizedDescription)")
                    }
                }
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.")
        }
    }
}
