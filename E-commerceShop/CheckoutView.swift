//
//  CheckoutView.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/05/2025.
//

import SwiftUI

struct CheckoutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Paiement sécurisé avec Stripe")
                .font(.title2)
                .padding()
            
            Image(systemName: "creditcard")
                .resizable()
                .frame(width: 80, height: 60)
                .foregroundStyle(.blue)
            
            Text("Redirection vers l'interface de paiement...")
                .foregroundColor(.gray)
            
            ProgressView()
        }
        .navigationTitle("Paiement")
        .onAppear {
            // Backend
        }
    }
}
