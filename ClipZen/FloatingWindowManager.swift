import AppKit

class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var windowController: FloatingWindowController?
    
    private init() {}
    
    func showWindow() {
        if windowController == nil {
            windowController = FloatingWindowController()
        }
        
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
} 