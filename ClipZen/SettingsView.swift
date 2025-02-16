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
        VStack(spacing: 20) {
            // Tema Seçimi
            GroupBox(label: localizedText("appearance", systemImage: "paintbrush")) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker(selection: $themeMode) {
                        Label(localizationManager.localizedString(for: "system"), systemImage: "circle.lefthalf.filled")
                            .tag(ThemeMode.system)
                        Label(localizationManager.localizedString(for: "light"), systemImage: "sun.max")
                            .tag(ThemeMode.light)
                        Label(localizationManager.localizedString(for: "dark"), systemImage: "moon")
                            .tag(ThemeMode.dark)
                    } label: {
                        localizedText("theme")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // Şeffaflık Ayarı
            GroupBox(label: localizedText("window_opacity", systemImage: "slider.horizontal.3")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Slider(value: $opacity, in: 0.5...1.0, step: 0.05)
                            .tint(.accentColor)
                        Text("\(Int(opacity * 100))%")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // Kısayol Ayarı
            GroupBox(label: localizedText("shortcut", systemImage: "keyboard")) {
                VStack(spacing: 8) {
                    HStack {
                        localizedText("show_clipboard_history")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            isRecordingShortcut.toggle()
                            shortcutError = nil
                        }) {
                            HStack {
                                if isRecordingShortcut {
                                    localizedText("waiting_for_key")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(formatShortcut(currentShortcut))
                                }
                            }
                            .frame(width: 150)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecordingShortcut ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focusable(false)
                    }
                    
                    if isRecordingShortcut {
                        localizedText("press_new_shortcut")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let error = shortcutError {
                        localizedText(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // Dil Seçimi
            GroupBox(label: localizedText("language", systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(selection: $selectedLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    } label: {
                        localizedText("select_language")
                    }
                    .onChange(of: selectedLanguage) { oldValue, newValue in
                        localizationManager.setLanguage(newValue)
                    }
                    
                    // Mevcut sistem dilini göster
                    localizedText("current_system_language", Language.systemLanguage.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            Spacer()
            
            // Saptanmış Değerlere Dön butonu
            Button(action: resetToDefaults) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    localizedText("reset_to_defaults")
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 350, height: 350)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            }
        )
        .opacity(opacity)
        .preferredColorScheme(themeMode.colorScheme)
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

// Şeffaf GroupBox stili
struct TransparentGroupBox: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
                .font(.headline)
                .foregroundColor(.secondary)
            
            configuration.content
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
        }
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

