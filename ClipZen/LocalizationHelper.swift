import Foundation

enum Language: String, CaseIterable, Codable {
    case system = "system"
    case english = "en"
    case german = "de"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case russian = "ru"
    case turkish = "tr"
    
    static var systemDefault: Language {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return Language(rawValue: languageCode) ?? .english
    }
    
    var displayName: String {
        if self == .system {
            return NSLocalizedString("system_language", comment: "")
        }
        return Locale.current.localizedString(forIdentifier: rawValue) ?? rawValue
    }
    
    var bundle: Bundle? {
        if self == .system {
            return Bundle.main
        }
        return Bundle.main.path(forResource: rawValue, ofType: "lproj").flatMap(Bundle.init)
    }
}

func LocalizedString(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    if args.isEmpty {
        return format
    }
    return String(format: format, arguments: args)
}

// Bundle extension for dynamic localization
extension Bundle {
    static var currentLanguageBundle: Bundle = .main
    
    func loadAndSetBundle(_ bundle: Bundle) {
        Bundle.currentLanguageBundle = bundle
    }
    
    static func localizedString(forKey key: String, value: String?, table: String?) -> String {
        return currentLanguageBundle.localizedString(forKey: key, value: value, table: table)
    }
} 