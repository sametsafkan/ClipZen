import SwiftUI
import Carbon // EventHotKey için gerekli

struct SettingsView: View {
    @AppStorage("windowOpacity") private var opacity = 0.9
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedLanguage: Language
    
    // ShortcutKey için özel AppStorage ve State
    @AppStorage("shortcutKey") private var shortcutKeyData: Data = {
        try! JSONEncoder().encode(ShortcutKey.default)
    }()
    
    @State private var isRecordingShortcut = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentShortcut: ShortcutKey
    @State private var shortcutError: String? = nil
    
    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
        let decoder = JSONDecoder()
        let defaultShortcut = ShortcutKey.default
        
        // UserDefaults'tan kısayolu yükle veya varsayılanı kullan
        if let data = UserDefaults.standard.data(forKey: "shortcutKey"),
           let decoded = try? decoder.decode(ShortcutKey.self, from: data) {
            _currentShortcut = State(initialValue: decoded)
        } else {
            _currentShortcut = State(initialValue: defaultShortcut)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Tema Seçimi
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label {
                        Text(localizationManager.localizedString(for: "appearance"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "paintbrush")
                            .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 4)
                    
                    Picker(selection: $themeMode) {
                        Label(localizationManager.localizedString(for: "system"), systemImage: "circle.lefthalf.filled")
                            .tag(ThemeMode.system)
                        Label(localizationManager.localizedString(for: "light"), systemImage: "sun.max")
                            .tag(ThemeMode.light)
                        Label(localizationManager.localizedString(for: "dark"), systemImage: "moon")
                            .tag(ThemeMode.dark)
                    } label: {
                        Text(localizationManager.localizedString(for: "theme"))
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 2)
                }
                .padding(16)
            }
            .groupBoxStyle(PremiumGroupBox())
            
            // Şeffaflık Ayarı
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label {
                        Text(localizationManager.localizedString(for: "window_opacity"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.purple)
                    }
                    .padding(.bottom, 4)
                    
                    HStack(spacing: 16) {
                        Slider(value: $opacity, in: 0.5...1.0, step: 0.05)
                            .tint(.purple)
                        
                        Text("\(Int(opacity * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                }
                .padding(16)
            }
            .groupBoxStyle(PremiumGroupBox())
            
            // Kısayol Ayarı
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label {
                        Text(localizationManager.localizedString(for: "shortcut"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "keyboard")
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom, 4)
                    
                    HStack {
                        Text(localizationManager.localizedString(for: "show_clipboard_history"))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            isRecordingShortcut.toggle()
                            shortcutError = nil
                        }) {
                            Text(isRecordingShortcut ? 
                                 localizationManager.localizedString(for: "waiting_for_key") :
                                 formatShortcut(currentShortcut))
                                .frame(width: 150)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isRecordingShortcut ? Color.accentColor : Color.secondary.opacity(0.2), 
                                               lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let error = shortcutError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
            }
            .groupBoxStyle(PremiumGroupBox())
            
            // Dil Seçimi
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label {
                        Text(localizationManager.localizedString(for: "language"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(.orange)
                    }
                    .padding(.bottom, 4)
                    
                    Picker(selection: $selectedLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    } label: {
                        Text(localizationManager.localizedString(for: "select_language"))
                    }
                    .onChange(of: selectedLanguage) { oldValue, newValue in
                        localizationManager.setLanguage(newValue)
                    }
                    
                    Text(localizationManager.localizedString(for: "current_system_language", 
                         Language.systemLanguage.displayName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .groupBoxStyle(PremiumGroupBox())
            
            Spacer()
            
            // Saptanmış Değerlere Dön butonu
            Button(action: resetToDefaults) {
                Label {
                    Text(localizationManager.localizedString(for: "reset_to_defaults"))
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(20)
        .frame(width: 460)
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.8)
                
                if themeMode.colorScheme == .dark {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color(nsColor: .windowBackgroundColor).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
        }
        .environment(\.colorScheme, themeMode.colorScheme)
        .onChange(of: themeMode) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                if let window = NSApp.windows.first(where: { $0.title == localizationManager.localizedString(for: "settings") }) {
                    window.appearance = newValue == .dark ? .init(named: .darkAqua) : .init(named: .aqua)
                }
            }
        }
        .onChange(of: opacity) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                if let window = NSApp.windows.first(where: { $0.title == localizationManager.localizedString(for: "settings") }) {
                    window.alphaValue = newValue
                }
            }
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onChange(of: currentShortcut) { oldValue, newValue in
            if let encoded = try? JSONEncoder().encode(newValue) {
                shortcutKeyData = encoded
                NotificationCenter.default.post(
                    name: .shortcutChanged,
                    object: newValue
                )
            }
        }
        .id("settings_view_\(localizationManager.currentLanguage.rawValue)")
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecordingShortcut else { return }
        
        // ESC tuşu ile iptal etme
        if event.keyCode == 53 {
            isRecordingShortcut = false
            shortcutError = nil
            return
        }
        
        // Sadece modifier tuşlarına basıldığında işlem yapma
        if event.type == .flagsChanged {
            return
        }
        
        // Modifier'ları al
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        // En az bir modifier tuşu gerekli
        if modifiers.isEmpty {
            shortcutError = localizationManager.localizedString(for: "shortcut_error_modifier")
            return
        }
        
        let newShortcut = ShortcutKey(
            keyCode: UInt32(event.keyCode),
            modifiers: ShortcutKey.carbonModifiers(from: modifiers)
        )
        
        // Kısayolu test et
        let hotKeyID = EventHotKeyID(signature: 0x5A4E_4C43, id: 1)
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            newShortcut.keyCode,
            newShortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
        
        if status == noErr {
            shortcutError = nil
            updateShortcut(newShortcut)
            isRecordingShortcut = false
        } else {
            switch status {
            case -9868: // kHIErrorInvalidModifiers
                shortcutError = localizationManager.localizedString(for: "shortcut_error_invalid")
            case -9870: // kHIErrorHotKeyExists
                shortcutError = localizationManager.localizedString(for: "shortcut_error_exists")
            default:
                shortcutError = localizationManager.localizedString(for: "shortcut_error_generic", status)
            }
        }
    }
    
    private func updateShortcut(_ shortcut: ShortcutKey) {
        currentShortcut = shortcut
    }
    
    private func formatShortcut(_ shortcut: ShortcutKey) -> String {
        var description = ""
        let modifiers = shortcut.cocoaModifiers
        
        // Modifier sıralaması: Control, Option, Shift, Command
        if modifiers.contains(.control) { description += "⌃" }
        if modifiers.contains(.option) { description += "⌥" }
        if modifiers.contains(.shift) { description += "⇧" }
        if modifiers.contains(.command) { description += "⌘" }
        
        // Eğer hiç modifier yoksa "Yok" göster
        if description.isEmpty {
            description = localizationManager.localizedString(for: "none")
        }
        
        // Tuş kodunu ekle
        if let key = KeyCodeMap[Int(shortcut.keyCode)] {
            if description != localizationManager.localizedString(for: "none") {
                description += key
            } else {
                description = key
            }
        }
        
        return description
    }
    
    private func resetToDefaults() {
        themeMode = .system
        opacity = 0.9
        // Dili sistem diline sıfırla
        selectedLanguage = Language.systemLanguage
        // Kısayolu sıfırla
        let defaultShortcut = ShortcutKey.default
        updateShortcut(defaultShortcut)
        
        // Animasyonlu geçiş için küçük bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Pencereyi sallayarak geri bildirim ver
            if let window = NSApp.windows.first(where: { $0.title == localizationManager.localizedString(for: "settings") }) {
                window.performShakeAnimation()
            }
        }
    }
}

// Notification için extension
extension Notification.Name {
    static let shortcutChanged = Notification.Name("shortcutChanged")
}

// Pencere sallama animasyonu için extension
extension NSWindow {
    func performShakeAnimation() {
        let numberOfShakes = 3
        let durationOfShake = 0.2
        let vigourOfShake: CGFloat = 2.5
        
        let frame = self.frame
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.duration = durationOfShake
        animation.repeatCount = Float(numberOfShakes)
        animation.values = [
            frame.origin.x - vigourOfShake,
            frame.origin.x + vigourOfShake,
            frame.origin.x - vigourOfShake,
            frame.origin.x + vigourOfShake,
            frame.origin.x
        ]
        animation.autoreverses = false
        animation.isRemovedOnCompletion = true
        
        self.animations = ["frame": animation]
        self.animator().setFrameOrigin(frame.origin)
    }
}

// Premium GroupBox stili
struct PremiumGroupBox: GroupBoxStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? 
                          Color.black.opacity(0.3) : 
                          Color.white.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                // Subtle border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        colorScheme == .dark ?
                        Color.white.opacity(0.1) :
                        Color.black.opacity(0.1),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(
            color: colorScheme == .dark ?
            .black.opacity(0.2) :
            .black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

// NSVisualEffectView için wrapper
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// View builder extension
extension SettingsView {
    func localizedText(_ key: String, systemImage: String) -> some View {
        Label {
            Text(LocalizationManager.shared.localizedString(for: key))
        } icon: {
            Image(systemName: systemImage)
        }
    }
    
    func localizedText(_ key: String, _ args: CVarArg...) -> some View {
        Text(LocalizationManager.shared.localizedString(for: key, args))
    }
}

// Label stilleri için extension
extension Label where Title == Text, Icon == Image {
    func premiumLabelStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.primary)
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
} 

