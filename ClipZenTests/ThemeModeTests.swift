import XCTest
import SwiftUI
@testable import ClipZen

final class ThemeModeTests: XCTestCase {
    func testSystemThemeDetection() {
        // Given
        let themeMode = ThemeMode.system
        
        // When
        let colorScheme = themeMode.colorScheme
        
        // Then
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        XCTAssertEqual(colorScheme, isDark ? .dark : .light)
    }
    
    func testLightTheme() {
        // Given
        let themeMode = ThemeMode.light
        
        // When
        let colorScheme = themeMode.colorScheme
        
        // Then
        XCTAssertEqual(colorScheme, .light)
    }
    
    func testDarkTheme() {
        // Given
        let themeMode = ThemeMode.dark
        
        // When
        let colorScheme = themeMode.colorScheme
        
        // Then
        XCTAssertEqual(colorScheme, .dark)
    }
} 