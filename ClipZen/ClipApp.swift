import SwiftUI
import AppKit
import Carbon

@main
struct ClipZen: App {
    // Ana uygulama durumunu yöneten state object
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    // Klavye monitörünü saklamak için bir sınıf oluşturuyoruz
    class KeyboardMonitor {
        private var eventHandler: EventHandlerRef?
        private var hotKeyRef: EventHotKeyRef?
        private let eventHandlerCallback: EventHandlerUPP
        
        init() {
            print("⌨️ Klavye kısayolları ayarlanıyor...")
            
            // Event handler callback'i oluştur
            eventHandlerCallback = { _, eventRef, _ -> OSStatus in
                if let eventRef = eventRef {
                    var hotKeyID = EventHotKeyID()
                    GetEventParameter(
                        eventRef,
                        UInt32(kEventParamDirectObject),
                        UInt32(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )
                    
                    DispatchQueue.main.async {
                        FloatingWindowManager.shared.showWindow()
                    }
                }
                return noErr
            }
            
            // Kısayol değişikliklerini dinle
            NotificationCenter.default.addObserver(
                forName: AppConstants.shortcutChangedNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let newShortcut = notification.object as? ShortcutKey {
                    self?.updateShortcut(newShortcut)
                }
            }
            
            setupShortcut()
        }
        
        deinit {
            cleanup()
        }
        
        private func cleanup() {
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
            if let hotKey = hotKeyRef {
                UnregisterEventHotKey(hotKey)
                hotKeyRef = nil
            }
        }
        
        private func setupShortcut() {
            if let shortcutData = UserDefaults.standard.data(forKey: "shortcutKey"),
               let savedShortcut = try? JSONDecoder().decode(ShortcutKey.self, from: shortcutData) {
                updateShortcut(savedShortcut)
            } else {
                updateShortcut(ShortcutKey.default)
            }
        }
        
        private func updateShortcut(_ shortcut: ShortcutKey) {
            cleanup()
            
            var keyboardEventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            
            let hotKeyID = EventHotKeyID(signature: 0x5A4E_4C43, id: 1)
            
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )
            
            if status == noErr {
                print("✅ Yeni kısayol kaydedildi: \(shortcut.keyCode) + \(shortcut.modifiers)")
                
                let handlerStatus = InstallEventHandler(
                    GetEventDispatcherTarget(),
                    eventHandlerCallback,
                    1,
                    &keyboardEventType,
                    nil,
                    &eventHandler
                )
                
                if handlerStatus == noErr {
                    print("✅ Event handler başarıyla kaydedildi")
                } else {
                    print("❌ Event handler kaydedilemedi: \(handlerStatus)")
                }
            } else {
                print("❌ Kısayol kaydedilemedi: \(status)")
            }
        }
    }
    
    private let keyboardMonitor = KeyboardMonitor()
    private let statusItem: NSStatusItem
    
    // Mevcut kısayolu saklamak için
    @State private var currentShortcut: ShortcutKey
    
    init() {
        _ = CoreDataManager.shared
        
        // Kaydedilmiş kısayolu yükle
        if let shortcutData = UserDefaults.standard.data(forKey: "shortcutKey"),
           let savedShortcut = try? JSONDecoder().decode(ShortcutKey.self, from: shortcutData) {
            _currentShortcut = State(initialValue: savedShortcut)
        } else {
            _currentShortcut = State(initialValue: ShortcutKey.default)
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipZen")
            button.image?.isTemplate = true
        }
        
        setupStatusBarMenu(with: currentShortcut)
        
        // Kısayol değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: AppConstants.shortcutChangedNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let newShortcut = notification.object as? ShortcutKey {
                currentShortcut = newShortcut
                updateMenuShortcut(newShortcut)
            }
        }
        
        // Dil değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { [self] _ in
            updateStatusBarMenu()
        }
    }
    
    private func updateMenuShortcut(_ shortcut: ShortcutKey) {
        guard let menu = statusItem.menu else { return }
        
        // Kopyalama Geçmişi menü öğesini bul
        if let historyItem = menu.items.first(where: { $0.title == "Kopyalama Geçmişi" }) {
            // Modifier'ları ayarla
            let modifiers = shortcut.cocoaModifiers
            historyItem.keyEquivalentModifierMask = modifiers
            
            // Tuş kodunu karaktere çevir
            if let key = KeyCodeMap[Int(shortcut.keyCode)] {
                historyItem.keyEquivalent = key.lowercased()
            }
        }
    }
    
    private func updateStatusBarMenu() {
        setupStatusBarMenu(with: currentShortcut)
    }
    
    private func setupStatusBarMenu(with shortcut: ShortcutKey) {
        let menu = NSMenu()
        
        // Kopyalama Geçmişi
        let historyItem = NSMenuItem()
        historyItem.title = LocalizedString("clipboard_history")
        historyItem.action = #selector(NSApplication.shared.showClipboardHistory(_:))
        
        // Kısayolu ayarla
        let modifiers = shortcut.cocoaModifiers
        historyItem.keyEquivalentModifierMask = modifiers
        if let key = KeyCodeMap[Int(shortcut.keyCode)] {
            historyItem.keyEquivalent = key.lowercased()
        }
        
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Ayarlar (kısayol olmadan)
        let preferencesItem = NSMenuItem()
        preferencesItem.title = "Ayarlar"
        preferencesItem.action = #selector(NSApplication.shared.showPreferences(_:))
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Çıkış
        let quitItem = NSMenuItem()
        quitItem.title = "Çıkış"
        quitItem.action = #selector(NSApplication.terminate(_:))
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
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