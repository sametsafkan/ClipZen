import Foundation
import SwiftUI
import AppKit

// MARK: - Notifications
extension Notification.Name {
    static let localizationChanged = Notification.Name("com.clipzen.localization.changed")
}

// MARK: - Bundle Extensions
private var bundleKey: UInt8 = 0

extension Bundle {
    static var languageBundle: Bundle {
        get {
            return objc_getAssociatedObject(Bundle.main, &bundleKey) as? Bundle ?? Bundle.main
        }
        set {
            objc_setAssociatedObject(Bundle.main, &bundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setLanguageBundle(_ bundle: Bundle) {
        Bundle.languageBundle = bundle
        UserDefaults.standard.set([bundle.localizations.first ?? "en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    static func localizedString(forKey key: String, value: String? = nil, table: String? = nil) -> String {
        return Bundle.languageBundle.localizedString(forKey: key, value: value, table: table)
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published private(set) var currentLanguage: Language {
        didSet {
            loadAndValidateTranslations()
            NotificationCenter.default.post(name: .localizationChanged, object: currentLanguage)
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "language")
        }
    }
    
    private var stringTables: [Language: [String: String]] = [:]
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "language"),
           let lang = Language(rawValue: savedLanguage) {
            currentLanguage = lang
        } else {
            currentLanguage = Language.systemLanguage
        }
        
        loadAndValidateTranslations()
        updateBundle()
    }
    
    private func updateBundle() {
        if let languageBundle = currentLanguage.bundle {
            Bundle.main.setLanguageBundle(languageBundle)
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
                
                NotificationCenter.default.post(
                    name: .localizationChanged,
                    object: self?.currentLanguage
                )
                
                NSApp.windows.forEach { window in
                    window.contentView?.needsDisplay = true
                    window.contentView?.needsLayout = true
                }
            }
        }
    }
    
    private func loadAndValidateTranslations() {
        // Tüm dil dosyalarını yükle
        for language in Language.allCases {
            if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language.rawValue),
               let strings = NSDictionary(contentsOfFile: path) as? [String: String] {
                stringTables[language] = strings
            }
        }
        
        // Eksik çevirileri kontrol et
        #if DEBUG
        validateTranslations()
        #endif
    }
    
    private func validateTranslations() {
        guard let englishStrings = stringTables[.english] else {
            assertionFailure("❌ İngilizce dil dosyası bulunamadı!")
            return
        }
        
        var hasErrors = false
        
        // Her dil için eksik çevirileri kontrol et
        for language in Language.allCases where language != .english {
            guard let translations = stringTables[language] else {
                print("⚠️ \(language.displayName) dil dosyası bulunamadı!")
                hasErrors = true
                continue
            }
            
            // Eksik anahtarları bul
            let missingKeys = Set(englishStrings.keys).subtracting(translations.keys)
            if !missingKeys.isEmpty {
                hasErrors = true
                print("\n📝 \(language.displayName) dilinde eksik çeviriler:")
                missingKeys.forEach { key in
                    print("   - \(key): \(englishStrings[key] ?? "")")
                }
            }
        }
        
        // Eksik çeviri varsa assertion hatası ver
        if hasErrors {
            assertionFailure("⚠️ Eksik çeviriler tespit edildi! Lütfen tamamlayın.")
        } else {
            print("✅ Tüm çeviriler tam!")
        }
    }
    
    func setLanguage(_ language: Language) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        updateBundle()
    }
    
    func localizedString(for key: String, _ args: CVarArg...) -> String {
        if let translation = stringTables[currentLanguage]?[key] {
            return args.isEmpty ? translation : String(format: translation, arguments: args)
        }
        
        if let englishTranslation = stringTables[.english]?[key] {
            return args.isEmpty ? englishTranslation : String(format: englishTranslation, arguments: args)
        }
        
        return key
    }
}

// MARK: - View Extensions
extension View {
    func localizedText(_ key: String, _ args: CVarArg...) -> some View {
        let manager = LocalizationManager.shared
        return Text(manager.localizedString(for: key, args))
            .id("localized_\(key)_\(manager.currentLanguage.rawValue)")
    }
}

// MARK: - NSMenuItem Extensions
extension NSMenuItem {
    func setLocalizedTitle(_ key: String, _ args: CVarArg...) {
        let manager = LocalizationManager.shared
        self.title = manager.localizedString(for: key, args)
    }
}

// MARK: - Environment
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
} 