import SwiftUI

struct SocialLinksView: View {
    var body: some View {
        List {
            Link(destination: URL(string: "https://www.instagram.com")!) {
                Label("Instagram", systemImage: "camera")
            }

            Link(destination: URL(string: "https://www.twitter.com")!) {
                Label("Twitter", systemImage: "bird")
            }

            Link(destination: URL(string: "https://www.facebook.com")!) {
                Label("Facebook", systemImage: "f.square")
            }
        }
        .navigationTitle("Réseaux sociaux")
        .navigationBarTitleDisplayMode(.inline)
    }
}
