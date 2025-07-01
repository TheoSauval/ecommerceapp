import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService.shared
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sécurité")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showCurrentPassword {
                                TextField("Mot de passe actuel", text: $currentPassword)
                            } else {
                                SecureField("Mot de passe actuel", text: $currentPassword)
                            }
                            
                            Button(action: {
                                showCurrentPassword.toggle()
                            }) {
                                Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("Nouveau mot de passe")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showNewPassword {
                                TextField("Nouveau mot de passe", text: $newPassword)
                            } else {
                                SecureField("Nouveau mot de passe", text: $newPassword)
                            }
                            
                            Button(action: {
                                showNewPassword.toggle()
                            }) {
                                Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if !newPassword.isEmpty {
                            PasswordStrengthView(password: newPassword)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirmer le nouveau mot de passe", text: $confirmPassword)
                            } else {
                                SecureField("Confirmer le nouveau mot de passe", text: $confirmPassword)
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if !confirmPassword.isEmpty && newPassword != confirmPassword {
                            Text("Les mots de passe ne correspondent pas")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
                
                Section {
                    Button(action: changePassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Changer le mot de passe")
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Changer le mot de passe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6 &&
        currentPassword != newPassword
    }
    
    private func changePassword() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        let passwordData = PasswordChange(
            oldPassword: currentPassword,
            newPassword: newPassword
        )
        
        userService.changePassword(passwordData: passwordData) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    successMessage = "Mot de passe changé avec succès !"
                    // Vider les champs après un délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                        dismiss()
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        
        switch score {
        case 0...1: return .weak
        case 2...3: return .medium
        case 4...5: return .strong
        default: return .weak
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Force du mot de passe:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(strength.description)
                    .font(.caption)
                    .foregroundColor(strength.color)
            }
            
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < strength.score ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
        }
    }
}

enum PasswordStrength {
    case weak, medium, strong
    
    var score: Int {
        switch self {
        case .weak: return 1
        case .medium: return 3
        case .strong: return 5
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Faible"
        case .medium: return "Moyen"
        case .strong: return "Fort"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

#Preview {
    ChangePasswordView()
} 