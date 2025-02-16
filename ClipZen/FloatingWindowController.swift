import SwiftUI
import AppKit

class FloatingWindowController: NSWindowController {
    private var eventMonitor: Any?
    private var themeObserver: Any?
    
    private func updateVisualEffect() {
        guard let window = self.window,
              let visualEffect = window.contentView as? NSVisualEffectView else { return }
        
        // Tema modunu UserDefaults'tan al
        let themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system
        
        switch themeMode {
        case .dark:
            visualEffect.material = .windowBackground
            window.backgroundColor = .clear
            visualEffect.appearance = .init(named: .darkAqua)
        case .light:
            visualEffect.material = .windowBackground
            window.backgroundColor = .clear
            visualEffect.appearance = .init(named: .aqua)
        case .system:
            let isDark = window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            visualEffect.material = .windowBackground
            window.backgroundColor = .clear
            visualEffect.appearance = isDark ? .init(named: .darkAqua) : .init(named: .aqua)
        }
    }
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.borderless, .titled],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        
        // Özel arka plan efekti ve yumuşak köşeler
        let visualEffect = NSVisualEffectView(frame: window.contentView?.frame ?? .zero)
        visualEffect.material = .windowBackground
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderWidth = 0
        visualEffect.layer?.backgroundColor = .clear
        
        // Çerçeveyi tamamen kaldır
        visualEffect.layer?.borderColor = .clear
        visualEffect.layer?.shadowOpacity = 0
        
        window.contentView = visualEffect
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true
        // SwiftUI view'ı bir container içine al
        let containerView = NSView(frame: visualEffect.bounds)
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.masksToBounds = true
        containerView.autoresizingMask = [.width, .height]
        
        let hostView = NSHostingView(
            rootView: FloatingWindow()
                .environment(\.localizationManager, LocalizationManager.shared)
                .id("floating_window_\(LocalizationManager.shared.currentLanguage.rawValue)")
        )
        hostView.frame = containerView.bounds
        hostView.autoresizingMask = [.width, .height]
        containerView.addSubview(hostView)
        
        visualEffect.addSubview(containerView)
        window.hasShadow = false
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 300, height: 400)
        
        self.init(window: window)
        
        // Tema değişikliğini dinle
        themeObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let defaults = notification.object as? UserDefaults,
               defaults.string(forKey: "themeMode") != nil {
                self?.updateVisualEffect()
            }
        }
        
        // İlk tema ayarını uygula
        updateVisualEffect()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .localizationChanged,
            object: nil
        )
        
        // ESC tuşu için event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC tuşu
                self?.window?.close()
                return nil
            }
            return event
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newWindow = NSWindow(
                contentRect: self.window?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.borderless, .titled],
                backing: .buffered,
                defer: false
            )
            
            newWindow.isMovableByWindowBackground = true
            newWindow.acceptsMouseMovedEvents = true
            newWindow.ignoresMouseEvents = false
            
            // Eski pencerenin özelliklerini kopyala
            newWindow.titlebarAppearsTransparent = true
            newWindow.titleVisibility = .hidden
            newWindow.standardWindowButton(.closeButton)?.isHidden = true
            newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
            newWindow.standardWindowButton(.zoomButton)?.isHidden = true
            
            newWindow.backgroundColor = .clear
            newWindow.isOpaque = false
            newWindow.hasShadow = true
            newWindow.level = .floating // Pencere seviyesini koru
            
            // Eski pencerenin konumunu kopyala
            if let oldFrame = self.window?.frame {
                newWindow.setFrame(oldFrame, display: true)
            } else {
                newWindow.center()
            }
            
            let visualEffect = NSVisualEffectView(frame: newWindow.contentView?.frame ?? .zero)
            visualEffect.material = .windowBackground
            visualEffect.blendingMode = .behindWindow
            visualEffect.state = .active
            visualEffect.wantsLayer = true
            visualEffect.layer?.cornerRadius = 12
            visualEffect.layer?.masksToBounds = true
            visualEffect.layer?.borderWidth = 0
            visualEffect.layer?.backgroundColor = .clear
            visualEffect.layer?.borderColor = .clear
            visualEffect.layer?.shadowOpacity = 0
            
            let containerView = NSView(frame: visualEffect.bounds)
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = 12
            containerView.layer?.masksToBounds = true
            containerView.autoresizingMask = [.width, .height]
            
            let hostView = NSHostingView(
                rootView: FloatingWindow()
                    .environment(\.localizationManager, LocalizationManager.shared)
                    .id("floating_window_\(LocalizationManager.shared.currentLanguage.rawValue)")
            )
            hostView.frame = containerView.bounds
            hostView.autoresizingMask = [.width, .height]
            containerView.addSubview(hostView)
            
            visualEffect.addSubview(containerView)
            
            // Yeni pencereyi ayarla ve göster
            newWindow.contentView = visualEffect
            
            // Eski pencereyi kapat ve yeni pencereyi göster
            let oldWindow = self.window
            self.window = newWindow
            self.window?.hasShadow = false
            self.showWindow(nil)
            oldWindow?.close()
            
            // Yeni pencereye tema ayarını uygula
            self.updateVisualEffect()
        }
    }
} 
