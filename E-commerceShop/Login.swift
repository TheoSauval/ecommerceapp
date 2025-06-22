import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connexion")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Mot de passe", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                authService.login(mail: email, password: password) { result in
                    switch result {
                    case .success:
                        // L'état de l'authentification est géré par l'AuthService
                        // et la vue changera automatiquement.
                        break
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }) {
                Text("Se connecter")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(authService.isLoading ? Color.gray : Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(authService.isLoading)
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthService.shared)
    }
}