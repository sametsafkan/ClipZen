import SwiftUI
import AppKit

class FloatingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = LocalizationManager.shared.localizedString(for: "clipboard_history")
        window.center()
        window.contentView = NSHostingView(
            rootView: FloatingWindow()
                .environment(\.localizationManager, LocalizationManager.shared)
                .id("floating_window_\(LocalizationManager.shared.currentLanguage.rawValue)")
        )
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.minSize = NSSize(width: 300, height: 400)
        
        self.init(window: window)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .localizationChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Yeni pencere oluştur
            let newWindow = NSWindow(
                contentRect: self.window?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            // Eski pencerenin özelliklerini kopyala
            newWindow.title = LocalizationManager.shared.localizedString(for: "clipboard_history")
            newWindow.contentView = NSHostingView(
                rootView: FloatingWindow()
                    .environment(\.localizationManager, LocalizationManager.shared)
                    .id("floating_window_\(LocalizationManager.shared.currentLanguage.rawValue)")
            )
            newWindow.isReleasedWhenClosed = false
            newWindow.level = .floating
            newWindow.titlebarAppearsTransparent = true
            newWindow.backgroundColor = .clear
            newWindow.isMovableByWindowBackground = true
            newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
            newWindow.standardWindowButton(.zoomButton)?.isHidden = true
            newWindow.minSize = NSSize(width: 300, height: 400)
            
            // Eski pencerenin konumunu kopyala
            if let oldFrame = self.window?.frame {
                newWindow.setFrame(oldFrame, display: true)
            } else {
                newWindow.center()
            }
            
            // Eski pencereyi kapat ve yeni pencereyi göster
            self.window?.close()
            self.window = newWindow
            self.showWindow(nil)
        }
    }
} 