import Foundation
import AppKit
import CoreData

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published private(set) var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int
    private let context = CoreDataManager.shared.viewContext
    
    private init() {
        print("🔄 ClipboardManager başlatılıyor...")
        self.lastChangeCount = NSPasteboard.general.changeCount
        print("📌 Başlangıç pano sayacı: \(lastChangeCount)")
        loadSavedItems()
        startMonitoring()
        print("👀 Pano izleme başlatıldı")
    }
    
    private func loadSavedItems() {
        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)]
        
        do {
            clipboardItems = try context.fetch(request)
            print("📚 Kayıtlı öğeler yüklendi - Toplam: \(clipboardItems.count)")
            
            // Tüm öğeleri göster
            for (index, item) in clipboardItems.enumerated() {
                if item.type == "text",
                   let content = item.content,
                   let text = String(data: content, encoding: .utf8) {
                    print("📝 Öğe \(index + 1): \(text.prefix(30))...")
                } else if item.type == "file" {
                    print("📄 Öğe \(index + 1): \(item.filename ?? "isimsiz")")
                }
                print("   🆔 ID: \(item.id?.uuidString ?? "nil")")
                print("    Timestamp: \(item.timestamp?.description ?? "nil")")
                print("   📊 Type: \(item.type ?? "nil")")
            }
        } catch {
            print("❌ Kayıtlı öğeler yüklenirken hata: \(error.localizedDescription)")
            print("🔍 Hata detayı: \(error)")
        }
    }
    
    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    fileprivate func checkText(_ types: [NSPasteboard.PasteboardType], _ pasteboard: NSPasteboard) {
        // Metin kontrolü
        if types.contains(.string) {
            if let text = pasteboard.string(forType: .string) {
                print("✍️ Metin kopyalandı: \(text.prefix(50))...")
                
                let item = ClipboardItem(context: context)
                item.id = UUID()
                item.timestamp = Date()
                item.type = "text"
                
                if let textData = text.data(using: .utf8) {
                    item.content = textData
                    clipboardItems.insert(item, at: 0)
                    try? context.save()
                    print("✅ Metin kaydedildi")
                }
            }
        }
    }
    
    fileprivate func checkFiles(_ pasteboard: NSPasteboard) -> Bool {
        // Dosya kontrolü
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            print("📂 Dosya(lar) kopyalandı: \(urls.count) adet")
            
            if urls.count > 0 {
                // Her dosya için ayrı kayıt oluştur
                for url in urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let item = ClipboardItem(context: context)
                        item.id = UUID()
                        item.timestamp = Date()
                        item.type = "file"
                        item.content = data
                        item.filename = url.lastPathComponent
                        item.fileExtension = url.pathExtension
                        
                        clipboardItems.insert(item, at: 0)
                        print("✅ Dosya kaydedildi: \(url.lastPathComponent)")
                    } catch {
                        print("❌ Dosya kaydedilirken hata: \(error)")
                    }
                }
                
                try? context.save()
                return true
            }
        }
        return false
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        
        lastChangeCount = pasteboard.changeCount
        print("📋 Pano değişikliği algılandı - changeCount: \(lastChangeCount)")
        
        // Panodaki tüm tipleri kontrol et
        let types = pasteboard.types ?? []
        print("📎 Pano içeriği tipleri: \(types)")
        
        if checkFiles(pasteboard) == false {
            checkText(types, pasteboard)
        }
        
        // Maksimum öğe sayısını kontrol et
        while clipboardItems.count > 50 {
            if let lastItem = clipboardItems.last {
                context.delete(lastItem)
                clipboardItems.removeLast()
            }
        }
        
        try? context.save()
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        timer?.invalidate() // Geçici olarak izlemeyi durdur
        
        pasteboard.clearContents()
        
        switch item.type {
        case "file":
            if let filename = item.filename,
               let content = item.content {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try content.write(to: tempURL)
                    if pasteboard.writeObjects([tempURL as NSURL]) {
                        print("✅ Dosya panoya kopyalandı: \(filename)")
                    } else {
                        print("❌ Dosya panoya kopyalanamadı")
                    }
                } catch {
                    print("❌ Dosya yazılırken hata: \(error)")
                }
            }
            
        case "text":
            if let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                if pasteboard.setString(text, forType: .string) {
                    print("✅ Metin panoya kopyalandı")
                } else {
                    print("❌ Metin panoya kopyalanamadı")
                }
            }
            
        default:
            print("⚠️ Bilinmeyen tip: \(item.type ?? "nil")")
        }
        
        lastChangeCount = pasteboard.changeCount
        startMonitoring() // İzlemeyi tekrar başlat
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(of: item) {
            context.delete(item)
            clipboardItems.remove(at: index)
            try? context.save()
            print("🗑️ Öğe silindi")
        }
    }
    
    func clearHistory() {
        for item in clipboardItems {
            context.delete(item)
        }
        clipboardItems.removeAll()
        try? context.save()
        print("🧹 Geçmiş temizlendi")
    }
}

// Bu struct'ı siliyoruz çünkü artık CoreData entity'si kullanıyoruz
// struct ClipboardItem: Identifiable, Equatable { ... }

// Bu enum'u da artık kullanmıyoruz
// enum ClipboardItemType { ... }
