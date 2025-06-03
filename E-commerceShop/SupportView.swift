import SwiftUI

struct SupportView: View {
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assistance client")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Une question ? Un souci ? Envoyez-nous un message et notre équipe vous répondra rapidement.")
                .foregroundColor(.gray)

            TextEditor(text: $message)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Button("Envoyer") {
                // Action d’envoi
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .navigationTitle("Assistance client")
        .navigationBarTitleDisplayMode(.inline)
    }
}
