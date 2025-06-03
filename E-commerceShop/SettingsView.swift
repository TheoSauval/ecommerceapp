import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false

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
        }
        .navigationTitle("Paramètres")
        .navigationBarTitleDisplayMode(.inline)
    }
}
