import SwiftUI

struct SearchBar: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
