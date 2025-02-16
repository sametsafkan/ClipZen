import SwiftUI
import AppKit

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            // Sistem temasını al
            let appearance = NSApplication.shared.effectiveAppearance
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
        }
    }
} 