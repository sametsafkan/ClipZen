import AppKit
import SwiftUI

class SettingsManager {
    static let shared = SettingsManager()
    private var windowController: SettingsWindowController?
    
    private init() {}
    
    func showWindow() {
        if windowController == nil {
            windowController = SettingsWindowController()
        }
        
        windowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
} 