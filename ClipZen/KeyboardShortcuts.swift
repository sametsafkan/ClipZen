import AppKit
import Carbon

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts()
    private var clipboardManager: ClipboardManager?
    
    func register(with manager: ClipboardManager) {
        self.clipboardManager = manager
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // cmd + v kısayolu için kontrol
        if event.modifierFlags.contains(.command) &&
           event.keyCode == kVK_ANSI_V {
            // En son kopyalanan öğeyi yapıştır
            if let lastItem = clipboardManager?.clipboardItems.first {
                clipboardManager?.copyToPasteboard(lastItem)
            }
        }
        
        // cmd + shift + v kısayolu için kontrol
        if event.modifierFlags.contains(.command) &&
           event.modifierFlags.contains(.shift) &&
           event.keyCode == kVK_ANSI_V {
            FloatingWindowManager.shared.showWindow()
        }
    }
}
