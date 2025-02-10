import SwiftUI
import AppKit
import Carbon

@main
struct ClipApp: App {
    // Ana uygulama durumunu yöneten state object
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    // Klavye monitörünü saklamak için bir sınıf oluşturuyoruz
    class KeyboardMonitor {
        private var eventHandler: EventHandlerRef?
        
        init() {
            print("⌨️ Klavye kısayolları ayarlanıyor...")
            
            // Kısayol için event type tanımlıyoruz
            var keyboardEventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            
            // Kısayol ID'si
            let hotKeyID = EventHotKeyID(signature: 0x5A4E_4C43, id: 1) // ZNLC
            
            // Kısayolu kaydet
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(kVK_ANSI_V),
                UInt32(cmdKey | optionKey),
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )
            
            if status == noErr {
                print("✅ Kısayol kaydedildi")
                
                // Event handler'ı oluştur
                InstallEventHandler(
                    GetEventDispatcherTarget(),
                    { (_, event, _) -> OSStatus in
                        print("🔑 Kısayol tetiklendi")
                        DispatchQueue.main.async {
                            print("🚀 Kopyalama geçmişi penceresi açılıyor...")
                            FloatingWindowManager.shared.showWindow()
                        }
                        return noErr
                    },
                    1,
                    &keyboardEventType,
                    nil,
                    &eventHandler
                )
            } else {
                print("❌ Kısayol kaydedilemedi: \(status)")
            }
        }
        
        deinit {
            if let handler = eventHandler {
                RemoveEventHandler(handler)
            }
        }
    }
    
    // Klavye monitörünü uygulama yaşam döngüsü boyunca tutuyoruz
    private let keyboardMonitor = KeyboardMonitor()
    
    // Uygulama başlatıldığında çalışacak kod
    init() {
        // Menü çubuğu simgesini ayarla
        setupStatusBarItem()
    }
    
    var body: some Scene {
        // Boş bir WindowGroup yerine Settings scene'i kullanacağız
        Settings {
            PreferencesView()
                .environmentObject(clipboardManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Kopyalama geçmişi için klavye kısayolu
            CommandGroup(after: .appSettings) {
                Button("Kopyalama Geçmişi") {
                    FloatingWindowManager.shared.showWindow()
                }
                .keyboardShortcut("v", modifiers: [.command, .option])
            }
        }
    }
    
    // Menü çubuğu simgesini oluştur
    private func setupStatusBarItem() {
        guard let statusBarIcon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipZen") else { return }
        statusBarIcon.isTemplate = true // Sistem temasına uyum için
        
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = statusBarIcon
        
        // Menü öğelerini oluştur
        let menu = NSMenu()
        let historyItem = NSMenuItem(title: "Kopyalama Geçmişi", 
                                   action: #selector(NSApplication.shared.showClipboardHistory(_:)), 
                                   keyEquivalent: "v")
        historyItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(historyItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Ayarlar", action: #selector(NSApplication.shared.showPreferences(_:)), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
}

// Uygulama genelinde kullanılacak extension'lar
extension NSApplication {
    @objc func showClipboardHistory(_ sender: Any?) {
        FloatingWindowManager.shared.showWindow()
    }
    
    @objc func showPreferences(_ sender: Any?) {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
} 