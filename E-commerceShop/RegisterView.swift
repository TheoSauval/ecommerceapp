import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode

    @State private var nom = ""
    @State private var prenom = ""
    @State private var age = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Créer un compte")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Nom", text: $nom)
            TextField("Prénom", text: $prenom)
            TextField("Âge", text: $age)
                .keyboardType(.numberPad)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            SecureField("Mot de passe", text: $password)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button(action: registerUser) {
                Text("S'inscrire")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(authService.isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(authService.isLoading)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
    }

    private func registerUser() {
        guard let ageInt = Int(age) else {
            errorMessage = "Veuillez entrer un âge valide."
            return
        }

        authService.register(
            nom: nom,
            prenom: prenom,
            age: ageInt,
            mail: email,
            password: password
        ) { result in
            switch result {
            case .success:
                // Connexion automatique après inscription
                authService.login(mail: email, password: password) { loginResult in
                    switch loginResult {
                    case .success:
                        presentationMode.wrappedValue.dismiss()
                    case .failure(let error):
                        self.errorMessage = "Inscription réussie, mais la connexion a échoué: \(error.localizedDescription)"
                    }
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthService.shared)
    }
}