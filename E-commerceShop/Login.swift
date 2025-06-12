import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var mail = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showRegister = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Connexion")
                .font(.largeTitle)

            TextField("Adresse mail", text: $mail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Mot de passe", text: $password)
                .textFieldStyle(.roundedBorder)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Se connecter") {
                AuthService.shared.login(mail: mail, password: password) { result in
                    switch result {
                    case .success:
                        isLoggedIn = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }

            Button("Créer un compte") {
                showRegister = true
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(isLoggedIn: $isLoggedIn)
            }
        }
        .padding()
    }
}