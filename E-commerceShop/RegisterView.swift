//
//  RegisterView.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 23/04/2025.
//

import SwiftUI

struct RegisterView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var prenom: String = ""
    @State var nom: String = ""
    @State var confirmPassword: String = ""
    var onRegisterSuccess: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            Text("Créer un compte")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Prenom", text: $prenom)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            TextField("Nom", text: $nom)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            SecureField("Mot de passe", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            SecureField("Confirmez votre mot de passe", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Button(action: {
                onRegisterSuccess?()
            }) {
                Text("Créer un compte")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Inscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}
