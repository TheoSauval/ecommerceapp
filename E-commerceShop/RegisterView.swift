import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = ""
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Créer un compte")
                .font(.largeTitle)
                .fontWeight(.bold)

            Form {
                Section(header: Text("Informations de compte")) {
                    TextField("Âge", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Mot de passe", text: $password)
                }

                Section(header: Text("Informations personnelles (Optionnel)")) {
                    TextField("Prénom", text: $firstName)
                    TextField("Nom de famille", text: $lastName)
                }

                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(action: {
                    guard let ageInt = Int(age) else {
                        // Gérer l'erreur si l'âge n'est pas un nombre valide
                        authService.errorMessage = "Veuillez entrer un âge valide."
                        return
                    }
                    
                    authService.register(
                        email: email,
                        password: password,
                        firstName: firstName.isEmpty ? nil : firstName,
                        lastName: lastName.isEmpty ? nil : lastName,
                        age: ageInt
                    ) { result in
                        switch result {
                        case .success:
                            // Log in the user automatically after successful registration
                            authService.login(email: email, password: password) { loginResult in
                                switch loginResult {
                                case .success:
                                    presentationMode.wrappedValue.dismiss()
                                case .failure(let error):
                                    // Handle login error
                                    print(error.localizedDescription)
                                }
                            }
                        case .failure(let error):
                            // Handle registration error
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .serverError(let message):
                                    authService.errorMessage = message
                                default:
                                    authService.errorMessage = error.localizedDescription
                                }
                            } else {
                                authService.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }) {
                    Text("S'inscrire")
                }
                .disabled(authService.isLoading)
            }
        }
        .navigationTitle("Créer un compte")
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthService.shared)
    }
}
