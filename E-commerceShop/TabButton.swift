import SwiftUI

struct TabButton: View {
    var systemIcon: String
    var index: Int
    @Binding var selectedTab: Int

    var isSelected: Bool {
        selectedTab == index
    }

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.gray.opacity(0.2) : Color.clear)
                    .frame(width: 50, height: 35)

                Image(systemName: systemIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}
