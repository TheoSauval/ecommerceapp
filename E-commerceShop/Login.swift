//
//  Login.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 23/04/2025.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    var onLoginSuccess: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            Text("Connexion")
                .font(.title)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            if isPasswordVisible {
                TextField("Mot de passe", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }

            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Text(isPasswordVisible ? "Cacher le mot de passe" : "Afficher le mot de passe")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Button(action: {
                // Simulation connexion réussie
                onLoginSuccess?()
            }) {
                Text("Se connecter")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Connexion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LoginView()
}
