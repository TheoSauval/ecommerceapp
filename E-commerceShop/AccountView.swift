import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if userService.isLoading {
                    ProgressView("Chargement du profil...")
                } else if let profile = userService.userProfile {
                    Form {
                        Section(header: Text("Informations Personnelles")) {
                            HStack {
                                Text("Prénom")
                                Spacer()
                                Text(profile.prenom)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Nom")
                                Spacer()
                                Text(profile.nom)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(profile.email)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Âge")
                                Spacer()
                                Text("\(profile.age)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section {
                            Button("Se déconnecter") {
                                authService.logout()
                            }
                            .foregroundColor(.red)
                        }
                    }
                } else if let errorMessage = userService.errorMessage {
                    VStack {
                        Text("Erreur de chargement")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.gray)
                        Button("Réessayer") {
                            userService.getProfile()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mon Compte")
            .onAppear {
                userService.getProfile()
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
            .environmentObject(AuthService.shared)
    }
}
