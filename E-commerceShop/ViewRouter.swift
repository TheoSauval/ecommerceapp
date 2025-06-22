import Foundation
import SwiftUI

class ViewRouter: ObservableObject {
    @Published var currentTab: Tab = .home
}

enum Tab {
    case home
    case favorites
    case cart
    case profile
} 