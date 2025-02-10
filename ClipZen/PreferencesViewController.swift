import SwiftUI

struct PreferencesView: View {
    @AppStorage("launchAtStartup") private var launchAtStartup = false
    @AppStorage("windowOpacity") private var windowOpacity = 0.9
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Başlangıçta Çalıştır", isOn: $launchAtStartup)
                    .onChange(of: launchAtStartup) { oldValue, newValue in
                        AppSettings.shared.launchAtStartup = newValue
                    }
                
                VStack(alignment: .leading) {
                    Text("Pencere Şeffaflığı")
                    HStack {
                        Slider(value: $windowOpacity, in: 0.5...1.0)
                            .onChange(of: windowOpacity) { oldValue, newValue in
                                AppSettings.shared.windowOpacity = newValue
                            }
                        Text("\(Int(windowOpacity * 100))%")
                            .frame(width: 45, alignment: .trailing)
                    }
                }
                
                Toggle("Koyu Tema", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { oldValue, newValue in
                        AppSettings.shared.isDarkMode = newValue
                    }
            }
        }
        .padding()
        .frame(width: 350, height: 150)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtStartup") private var launchAtStartup = false
    
    var body: some View {
        Form {
            Toggle("Başlangıçta Çalıştır", isOn: $launchAtStartup)
                .onChange(of: launchAtStartup) { newValue in
                    setLaunchAtStartup(newValue)
                }
            
            Divider()
            
            Text("Kısayol Tuşları")
                .font(.headline)
            
            HStack {
                Text("Clipboard Geçmişi:")
                Text("⌘ + ⇧ + V")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func setLaunchAtStartup(_ enabled: Bool) {
        // Başlangıçta çalıştırma ayarını kaydet
        // LaunchAtLogin framework'ü kullanılabilir
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("windowOpacity") private var windowOpacity = 0.9
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Text("Pencere Şeffaflığı")
                Slider(value: $windowOpacity, in: 0.5...1.0) {
                    Text("Şeffaflık")
                }
                
                Divider()
                
                Toggle("Koyu Tema", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { newValue in
                        updateAppearance(isDark: newValue)
                    }
            }
        }
        .padding()
    }
    
    private func updateAppearance(isDark: Bool) {
        // Tema değişikliğini uygula
        NSApp.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    }
} 