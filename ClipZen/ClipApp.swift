import SwiftUI
import AppKit
import Carbon

@main
struct ClipZen: App {
    // Ana uygulama durumunu yöneten state object
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Hot Key yönetimi için ayrı bir sınıf
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x5A4E_4C43, id: 1)
    private var keyboardEventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
    
    @Published private(set) var currentShortcut: ShortcutKey
    @Published var shortcutError: String?
    @Published var isRecordingShortcut = false
    
    private let statusItem: NSStatusItem
    
    private init() {
        // Kaydedilmiş kısayolu yükle
        if let shortcutData = UserDefaults.standard.data(forKey: "shortcutKey"),
           let savedShortcut = try? JSONDecoder().decode(ShortcutKey.self, from: shortcutData) {
            currentShortcut = savedShortcut
        } else {
            currentShortcut = ShortcutKey.default
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipZen")
            button.image?.isTemplate = true
        }
        
        setupStatusBarMenu()
        setupHotKey()
        
        // Dil değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .localizationChanged,
            object: nil
        )
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        // Kopyalama Geçmişi
        let historyItem = NSMenuItem()
        historyItem.title = LocalizationManager.shared.localizedString(for: "clipboard_history")
        historyItem.action = #selector(NSApplication.shared.showClipboardHistory(_:))
        
        // Kısayolu ayarla
        let modifiers = currentShortcut.cocoaModifiers
        historyItem.keyEquivalentModifierMask = modifiers
        if let key = KeyCodeMap[Int(currentShortcut.keyCode)] {
            historyItem.keyEquivalent = key.lowercased()
        }
        
        menu.addItem(historyItem)
        menu.addItem(NSMenuItem.separator())
        
        // Ayarlar
        let preferencesItem = NSMenuItem()
        preferencesItem.title = LocalizationManager.shared.localizedString(for: "settings")
        preferencesItem.action = #selector(NSApplication.shared.showPreferences(_:))
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Çıkış
        let quitItem = NSMenuItem()
        quitItem.title = LocalizationManager.shared.localizedString(for: "quit")
        quitItem.action = #selector(NSApplication.terminate(_:))
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func setupHotKey() {
        if let shortcutData = UserDefaults.standard.data(forKey: "shortcutKey"),
           let savedShortcut = try? JSONDecoder().decode(ShortcutKey.self, from: shortcutData) {
            let status = RegisterEventHotKey(
                savedShortcut.keyCode,
                savedShortcut.modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )
            
            if status == noErr {
                shortcutError = nil
                currentShortcut = savedShortcut
                isRecordingShortcut = false
                
                // Event handler'ı kaydet
                let handlerStatus = InstallEventHandler(
                    GetEventDispatcherTarget(),
                    eventHandlerCallback,
                    1,
                    &keyboardEventType,
                    nil,
                    &eventHandler
                )
                
                if handlerStatus != noErr {
                    print("❌ Event handler kaydedilemedi: \(handlerStatus)")
                }
            } else {
                switch status {
                case -9868: // kHIErrorInvalidModifiers
                    shortcutError = LocalizationManager.shared.localizedString(for: "shortcut_error_invalid")
                case -9870: // kHIErrorHotKeyExists
                    shortcutError = LocalizationManager.shared.localizedString(for: "shortcut_error_exists")
                default:
                    shortcutError = LocalizationManager.shared.localizedString(for: "shortcut_error_unknown")
                }
            }
        }
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.setupStatusBarMenu()
        }
    }
    
    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
    }
}

extension NSApplication {
    @objc func showClipboardHistory(_ sender: Any?) {
        FloatingWindowManager.shared.showWindow()
    }
    
    @objc func showPreferences(_ sender: Any?) {
        SettingsManager.shared.showWindow()
    }
}

// Event handler callback
private func eventHandlerCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    FloatingWindowManager.shared.showWindow()
    return noErr
} 
