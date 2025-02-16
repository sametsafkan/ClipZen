import Foundation
import AppKit
import SwiftUI
import Carbon


class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // Ayar anahtarları
    private enum Keys {
        static let launchAtStartup = "launchAtStartup"
        static let windowOpacity = "windowOpacity"
        static let isDarkMode = "isDarkMode"
        static let language = "language"
    }
    
    @AppStorage("windowOpacity") var opacity: Double = 0.9 {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("themeMode") var themeMode: ThemeMode = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var language: Language {
        didSet {
            // Dil değiştiğinde LocalizationManager'ı güncelle
            LocalizationManager.shared.setLanguage(language)
            updateAppearance(isDark: isDarkMode)
        }
    }
    
    // Başlangıçta çalıştırma ayarı
    var launchAtStartup: Bool {
        get { defaults.bool(forKey: Keys.launchAtStartup) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtStartup)
            setLaunchAtStartup(newValue)
        }
    }
    
    // Tema ayarı
    var isDarkMode: Bool {
        get { defaults.bool(forKey: Keys.isDarkMode) }
        set {
            defaults.set(newValue, forKey: Keys.isDarkMode)
            updateAppearance(isDark: newValue)
        }
    }
    
    private init() {
        // Kaydedilmiş dili yükle veya varsayılan olarak sistem dilini kullan
        if let savedLanguage = UserDefaults.standard.string(forKey: "language"),
           let lang = Language(rawValue: savedLanguage) {
            language = lang
        } else {
            language = Language.systemLanguage
        }
    }
    
    private func setLaunchAtStartup(_ enabled: Bool) {
        // LaunchAtLogin framework'ü kullanılabilir
        // Şimdilik boş bırakıyoruz
    }
    
    
    private func updateAppearance(isDark: Bool) {
        DispatchQueue.main.async {
            NSApp.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        }
    } 
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case system
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Shortcut Key
struct ShortcutKey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    static var `default` = ShortcutKey(
        keyCode: UInt32(kVK_ANSI_V),
        // Carbon framework'ünün beklediği modifier formatını kullan
        modifiers: UInt32(cmdKey | optionKey)
    )
    
    // NSEvent.ModifierFlags'den Carbon modifier'larına dönüştürme
    static func carbonModifiers(from cocoaModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        
        if cocoaModifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if cocoaModifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
        if cocoaModifiers.contains(.control) { carbonMods |= UInt32(controlKey) }
        if cocoaModifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        
        return carbonMods
    }
    
    // Carbon modifier'larından NSEvent.ModifierFlags'e dönüştürme
    var cocoaModifiers: NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        let mods = UInt(modifiers)
        
        if mods & UInt(cmdKey) != 0 { flags.insert(.command) }
        if mods & UInt(optionKey) != 0 { flags.insert(.option) }
        if mods & UInt(controlKey) != 0 { flags.insert(.control) }
        if mods & UInt(shiftKey) != 0 { flags.insert(.shift) }
        
        return flags
    }
}

// MARK: - Key Code Map
let KeyCodeMap: [Int: String] = [
    0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
    0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
    0x10: "Y", 0x11: "T", 0x1D: "9", 0x1B: "0", 0x18: "1", 0x19: "2", 0x1A: "3",
    0x14: "5", 0x15: "6", 0x16: "7", 0x17: "8", 0x1C: "-", 0x1E: "]", 0x21: "[",
    0x1F: "O", 0x23: "I", 0x22: "P", 0x2A: "\\",
    0x2D: "N", 0x2E: "M", 0x2B: ",", 0x2F: ".", 0x2C: "/", 0x24: "Return",
    0x30: "Tab", 0x31: "Space", 0x33: "Delete", 0x35: "Esc"
]

// MARK: - Constants
enum AppConstants {
    static let shortcutChangedNotification = Notification.Name("shortcutChanged")
}

// Dil değişikliği bildirimi için
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
