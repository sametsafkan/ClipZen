import SwiftUI
import AppKit
import Foundation

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    
    init(popover: NSPopover) {
        self.popover = popover
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        setupMenu()
        
        // Dil değişikliğini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .localizationChanged,
            object: nil
        )
    }
    
    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            button.action = #selector(togglePopover(_:))
        }
        
        updateMenuItems()
    }
    
    private func updateMenuItems() {
        let menu = NSMenu()
        
        // Menü öğelerini güncelle
        let showItem = NSMenuItem()
        showItem.setLocalizedTitle("show_clipboard_history")
        showItem.action = #selector(togglePopover(_:))
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem()
        quitItem.setLocalizedTitle("quit")
        quitItem.action = #selector(NSApplication.shared.terminate(_:))
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    private func showPopover(_ sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    private func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMenuItems()
        }
    }
} 