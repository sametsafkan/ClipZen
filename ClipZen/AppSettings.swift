import Foundation
import AppKit


class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // Ayar anahtarları
    private enum Keys {
        static let launchAtStartup = "launchAtStartup"
        static let windowOpacity = "windowOpacity"
        static let isDarkMode = "isDarkMode"
    }
    
    // Başlangıçta çalıştırma ayarı
    var launchAtStartup: Bool {
        get { defaults.bool(forKey: Keys.launchAtStartup) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtStartup)
            setLaunchAtStartup(newValue)
        }
    }
    
    // Pencere şeffaflığı (0.5-1.0 arası)
    var windowOpacity: Double {
        get { defaults.double(forKey: Keys.windowOpacity) }
        set { defaults.set(newValue, forKey: Keys.windowOpacity) }
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
        // Varsayılan değerleri ayarla
        if defaults.object(forKey: Keys.windowOpacity) == nil {
            defaults.set(0.9, forKey: Keys.windowOpacity)
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
