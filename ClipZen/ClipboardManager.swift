import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    // Kopyalanan öğeleri tutan dizi
    @Published private(set) var clipboardItems: [ClipboardItem] = []
    
    // Pasteboard değişikliklerini izlemek için timer
    private var timer: Timer?
    private var lastChangeCount: Int
    
    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    // Clipboard izlemeyi başlat
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    // Clipboard değişikliklerini kontrol et
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let text = pasteboard.string(forType: .string) {
                addItem(ClipboardItem(type: .text, content: text))
            } else if let image = pasteboard.data(forType: .tiff) {
                addItem(ClipboardItem(type: .image, content: image))
            }
        }
    }
    
    // Yeni öğe ekle
    private func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Aynı içeriği tekrar ekleme
            if !self.clipboardItems.contains(where: { $0.id == item.id }) {
                self.clipboardItems.insert(item, at: 0)
                
                // Maksimum 50 öğe sakla
                if self.clipboardItems.count > 50 {
                    self.clipboardItems.removeLast()
                }
            }
        }
    }
    
    // Seçilen öğeyi clipboard'a kopyala
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.content as? String {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imageData = item.content as? Data {
                pasteboard.setData(imageData, forType: .tiff)
            }
        }
    }
}

// Clipboard öğesi modeli
struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let type: ClipboardItemType
    let content: Any
    let timestamp = Date()
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ClipboardItemType {
    case text
    case image
} 