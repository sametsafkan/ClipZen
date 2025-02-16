import Foundation

enum Language: String, CaseIterable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case russian = "ru"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .german: return "Deutsch"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .russian: return "Русский"
        }
    }
    
    var bundle: Bundle? {
        guard let path = Bundle.main.path(forResource: self.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }
        return bundle
    }
    
    static var systemLanguage: Language {
        // Sistem dilini al
        let languageCode = NSLocale.current.language.languageCode?.identifier ?? "en"
        let regionCode = NSLocale.current.region?.identifier ?? ""
        
        // Tam dil kodunu oluştur (örn: "tr-TR", "en-US")
        let fullCode = regionCode.isEmpty ? languageCode : "\(languageCode)-\(regionCode)"
        
        // Debug için yazdır
        print("System language code: \(fullCode)")
        
        // Dil koduna göre Language enum'unu döndür
        switch languageCode {
        case "tr": return .turkish
        case "en": return .english
        case "de": return .german
        case "fr": return .french
        case "es": return .spanish
        case "it": return .italian
        case "ja": return .japanese
        case "ko": return .korean
        case "zh":
            // Çince için bölge koduna göre ayrım yap
            if regionCode == "TW" || regionCode == "HK" {
                return .traditionalChinese
            }
            return .simplifiedChinese
        default:
            return .english // Desteklenmeyen diller için varsayılan olarak İngilizce
        }
    }
} 
