import SwiftUI

struct PersonalInfoView: View {
    @State private var name = "Théo Sauval"
    @State private var email = "theo@email.com"
    @State private var phone = "+33 6 12 34 56 78"

    var body: some View {
        Form {
            Section(header: Text("Nom")) {
                TextField("Nom", text: $name)
            }

            Section(header: Text("Email")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
            }

            Section(header: Text("Téléphone")) {
                TextField("Téléphone", text: $phone)
                    .keyboardType(.phonePad)
            }
        }
        .navigationTitle("Mes coordonnées")
        .navigationBarTitleDisplayMode(.inline)
    }
}
