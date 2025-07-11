import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Connexion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Mot de passe", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    authService.login(email: email, password: password) { result in
                        switch result {
                        case .success:
                            // La navigation est gérée par le changement d'état dans AuthService
                            print("Login successful")
                            errorMessage = nil
                        case .failure(let error):
                            // Afficher l'erreur à l'utilisateur
                            print("Login failed: \(error.localizedDescription)")
                            errorMessage = error.localizedDescription
                        }
                    }
                }) {
                    Text("Se connecter")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading)
                
                NavigationLink(destination: RegisterView()) {
                    Text("Pas encore de compte ? S'inscrire")
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthService.shared)
    }
}
