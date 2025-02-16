import SwiftUI
import Carbon // EventHotKey için gerekli

struct SettingsView: View {
    @AppStorage("windowOpacity") private var opacity = 0.9
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @State private var selectedLanguage: Language = AppSettings.shared.language
    
    // ShortcutKey için özel AppStorage ve State
    @AppStorage("shortcutKey") private var shortcutKeyData: Data = {
        try! JSONEncoder().encode(ShortcutKey.default)
    }()
    
    @State private var isRecordingShortcut = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentShortcut: ShortcutKey
    @State private var shortcutError: String? = nil
    
    init() {
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
            GroupBox(label: Label("Görünüm", systemImage: "paintbrush")) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Tema", selection: $themeMode) {
                        Label("Sistem", systemImage: "circle.lefthalf.filled")
                            .tag(ThemeMode.system)
                        Label("Açık", systemImage: "sun.max")
                            .tag(ThemeMode.light)
                        Label("Koyu", systemImage: "moon")
                            .tag(ThemeMode.dark)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // Şeffaflık Ayarı
            GroupBox(label: Label("Pencere Şeffaflığı", systemImage: "slider.horizontal.3")) {
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
            GroupBox(label: Label("Kısayol", systemImage: "keyboard")) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Kopyalama Geçmişini Göster:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            isRecordingShortcut.toggle()
                            shortcutError = nil
                        }) {
                            HStack {
                                if isRecordingShortcut {
                                    Text("Tuş bekleniyor...")
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
                        Text("Yeni kısayol için tuş kombinasyonuna basın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let error = shortcutError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // Dil Seçimi
            GroupBox(label: Label(LocalizedString("language"), systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(LocalizedString("select_language"), selection: $selectedLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { oldValue, newValue in
                        AppSettings.shared.language = newValue
                    }
                }
                .padding(8)
            }
            .groupBoxStyle(TransparentGroupBox())
            
            Spacer()
            
            // Saptanmış Değerlere Dön butonu
            Button(action: {
                resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Saptanmış Değerlere Dön")
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
                if let window = NSApp.windows.first(where: { $0.title == "Ayarlar" }) {
                    window.appearance = newValue == .dark ? .init(named: .darkAqua) : .init(named: .aqua)
                }
            }
        }
        .onChange(of: opacity) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                if let window = NSApp.windows.first(where: { $0.title == "Ayarlar" }) {
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
                    name: AppConstants.shortcutChangedNotification,
                    object: newValue
                )
            }
        }
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
            shortcutError = "En az bir özel tuş (⌘, ⌥, ⌃, ⇧) gerekli"
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
                shortcutError = "Bu kısayol kombinasyonu geçersiz"
            case -9870: // kHIErrorHotKeyExists
                shortcutError = "Bu kısayol başka bir uygulama tarafından kullanılıyor"
            default:
                shortcutError = "Bu kısayol kullanılamıyor (Hata: \(status))"
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
            description = "Yok"
        }
        
        // Tuş kodunu ekle
        if let key = KeyCodeMap[Int(shortcut.keyCode)] {
            if description != "Yok" {
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
        selectedLanguage = .system
        // Kısayolu sıfırla
        let defaultShortcut = ShortcutKey.default
        updateShortcut(defaultShortcut)
        
        // Animasyonlu geçiş için küçük bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Pencereyi sallayarak geri bildirim ver
            if let window = NSApp.windows.first(where: { $0.title == "Ayarlar" }) {
                window.performShakeAnimation()
            }
        }
    }
}

// Notification için extension
extension Notification.Name {
    static let shortcutChanged = Notification.Name("shortcutChanged")
}

// Ayarlar penceresi kontrolcüsü
class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ayarlar"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // ESC tuşu için
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.target = window
            closeButton.action = #selector(NSWindow.close)
            closeButton.keyEquivalent = "\u{1b}" // ESC tuşu
        }
        
        self.init(window: window)
    }
}

// Ayarlar penceresi yöneticisi
class SettingsManager {
    static let shared = SettingsManager()
    private var windowController: SettingsWindowController?
    
    private init() {}
    
    func showWindow() {
        if windowController == nil {
            windowController = SettingsWindowController()
        }
        
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
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

