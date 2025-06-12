import SwiftUI

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) var dismiss

    @State private var nom = ""
    @State private var prenom = ""
    @State private var age = ""
    @State private var mail = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Nom", text: $nom)
                TextField("Prénom", text: $prenom)
                TextField("Âge", text: $age)
                    .keyboardType(.numberPad)
                TextField("Email", text: $mail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Mot de passe", text: $password)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button("S'inscrire") {
                    guard let ageInt = Int(age) else {
                        errorMessage = "Âge invalide"
                        return
                    }

                    AuthService.shared.register(
                        nom: nom,
                        prenom: prenom,
                        age: ageInt,
                        mail: mail,
                        password: password
                    ) { result in
                        switch result {
                        case .success:
                            isLoggedIn = true
                            dismiss()
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            .navigationTitle("Inscription")
        }
    }
}