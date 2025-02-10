import SwiftUI
import AppKit

struct FloatingWindow: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @AppStorage("windowOpacity") private var opacity = 0.9
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(clipboardManager.clipboardItems) { item in
                    ClipboardItemRowView(item: item)
                        .onTapGesture {
                            clipboardManager.copyToPasteboard(item)
                            dismiss()
                        }
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 400, height: 500)
        .opacity(opacity)
    }
}

// Pencere kontrolcüsü
class FloatingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Kopyalama Geçmişi"
        window.center()
        window.contentView = NSHostingView(rootView: FloatingWindow())
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.transient, .moveToActiveSpace]
        
        self.init(window: window)
    }
}

// URL şeması işleyicisi
class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var windowController: FloatingWindowController?
    
    private init() {
        print("📱 FloatingWindowManager başlatıldı")
    }
    
    func showWindow() {
        print("🪟 showWindow çağrıldı")
        
        if windowController == nil {
            print("🆕 Yeni pencere kontrolcüsü oluşturuluyor")
            windowController = FloatingWindowController()
        }
        
        print("📍 Pencere gösteriliyor")
        windowController?.showWindow(nil)
        
        print("⬆️ Uygulama aktifleştiriliyor")
        NSApp.activate(ignoringOtherApps: true)
    }
} 