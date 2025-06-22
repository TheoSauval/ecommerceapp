import SwiftUI

struct TabBarIcon: View {
    let systemIcon: String
    let index: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            Image(systemName: systemIcon)
                .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .black : .gray)
        }
    }
    
    private var isSelected: Bool {
        selectedTab == index
    }
} 