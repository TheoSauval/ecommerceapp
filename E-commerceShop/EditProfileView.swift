import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var userService = UserService.shared
    
    @State private var nom: String = ""
    @State private var prenom: String = ""
    @State private var age: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations Personnelles")) {
                    TextField("Nom", text: $nom)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Prénom", text: $prenom)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Âge", text: $age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            Text(isLoading ? "Sauvegarde..." : "Sauvegarder")
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Sauvegarder") {
                    saveProfile()
                }
                .disabled(isLoading || !isFormValid)
            )
            .onAppear {
                loadCurrentProfile()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(isSuccess ? "Succès" : "Erreur"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !prenom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(age) != nil
    }
    
    private func loadCurrentProfile() {
        if let profile = userService.userProfile {
            nom = profile.nom
            prenom = profile.prenom
            age = String(profile.age)
        }
    }
    
    private func saveProfile() {
        guard isFormValid else { return }
        
        guard let ageInt = Int(age) else {
            alertMessage = "L'âge doit être un nombre valide"
            showAlert = true
            return
        }
        
        isLoading = true
        
        let updateData = UserProfileUpdate(
            nom: nom.trimmingCharacters(in: .whitespacesAndNewlines),
            prenom: prenom.trimmingCharacters(in: .whitespacesAndNewlines),
            age: ageInt
        )
        
        userService.updateProfile(profileData: updateData) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let updatedProfile):
                    isSuccess = true
                    alertMessage = "Profil mis à jour avec succès"
                    showAlert = true
                    // Rafraîchir le profil pour s'assurer que les données sont à jour
                    userService.getProfile()
                    
                case .failure(let error):
                    isSuccess = false
                    alertMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AuthService.shared)
    }
} 