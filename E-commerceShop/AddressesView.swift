import SwiftUI

struct AddressesView: View {
    var body: some View {
        List {
            Section(header: Text("Adresse principale")) {
                VStack(alignment: .leading) {
                    Text("Théo Sauval")
                    Text("25 rue des Lilas")
                    Text("75010 Paris, France")
                }
            }

            Section(header: Text("Autres adresses")) {
                Button("Ajouter une adresse") {
                    // action d'ajout
                }
            }
        }
        .navigationTitle("Carnet d'adresses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
