import SwiftUI
import AppKit

class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = LocalizationManager.shared.localizedString(for: "settings")
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
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
            guard let window = self?.window else { return }
            window.title = LocalizationManager.shared.localizedString(for: "settings")
        }
    }
} 