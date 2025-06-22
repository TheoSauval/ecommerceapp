import SwiftUI

struct SupportView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Support Client")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Besoin d'aide ? Contactez-nous via les options ci-dessous.")
                .font(.body)
                .foregroundColor(.gray)

            Divider()

            SupportOption(icon: "phone.fill", text: "Appelez-nous")
            SupportOption(icon: "envelope.fill", text: "Envoyez-nous un e-mail")
            SupportOption(icon: "message.fill", text: "Chat en direct")

            Spacer()
        }
        .padding()
    }
}

struct SupportOption: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    SupportView()
}
