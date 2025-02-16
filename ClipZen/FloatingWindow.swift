import SwiftUI
import AppKit

struct FloatingWindow: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @AppStorage("windowOpacity") private var opacity = 0.9
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearAlert = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Arama çubuğu
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .imageScale(.small)
                TextField("Ara...", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            
            // Kopyalama geçmişi listesi
            List {
                ForEach(filteredItems) { item in
                    ClipboardItemView(item: item, onDelete: {
                        deleteItem(item)
                    })
                }
            }
            .listStyle(.plain)
            .background(.ultraThinMaterial)
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // Alt toolbar
            HStack {
                Text("\(clipboardManager.clipboardItems.count) öğe")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Spacer()
                
                Button(action: { showingClearAlert = true }) {
                    Label("Geçmişi Temizle", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(.ultraThinMaterial)
        }
        .frame(width: 400, height: 500)
        .opacity(opacity)
        .preferredColorScheme(themeMode.colorScheme)
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .alert("Geçmişi Temizle", isPresented: $showingClearAlert) {
            Button("İptal", role: .cancel) { }
            Button("Temizle", role: .destructive) {
                withAnimation(.easeInOut) {
                    clipboardManager.clearHistory()
                }
            }
        } message: {
            Text("Tüm kopyalama geçmişi silinecek. Bu işlem geri alınamaz.")
        }
    }
    
    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        }
        return clipboardManager.clipboardItems.filter { item in
            if let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                return text.localizedCaseInsensitiveContains(searchText)
            }
            return item.filename?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            clipboardManager.deleteItem(item)
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            if let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                Text(text)
                    .lineLimit(2)
                    .truncationMode(.middle)
            } else if let filename = item.filename {
                Label(filename, systemImage: "doc")
            }
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 12) {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        if let content = item.content {
                            NSPasteboard.general.setData(content, forType: .string)
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHovered = isHovered
            }
        }
    }
}

// Pencere kontrolcüsü
class FloatingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Kopyalama Geçmişi"
        window.center()
        window.contentView = NSHostingView(rootView: FloatingWindow())
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Minimum boyut
        window.minSize = NSSize(width: 300, height: 400)
        
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