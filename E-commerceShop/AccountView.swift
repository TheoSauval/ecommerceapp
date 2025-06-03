import SwiftUI

struct AccountView: View {
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoggedIn {
                    // ✅ Vue connectée
                    ProfileView(onLogout: {
                        isLoggedIn = false
                    })
                } else {
                    // ❌ Vue non connectée
                    VStack(spacing: 24) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .padding(.top, 40)

                        Text("Bienvenue dans votre espace client")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        NavigationLink(destination: LoginView(onLoginSuccess: {
                            isLoggedIn = true
                        })) {
                            Text("Se connecter")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink(destination: RegisterView(onRegisterSuccess: {
                            isLoggedIn = true
                        })) {
                            Text("Créer un compte")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Mon Compte")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
