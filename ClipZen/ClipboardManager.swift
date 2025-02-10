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
            
            // İlk birkaç öğeyi göster
            for (index, item) in clipboardItems.prefix(3).enumerated() {
                if item.type == "text",
                   let content = item.content,
                   let text = String(data: content, encoding: .utf8) {
                    print("📝 Öğe \(index + 1): \(text.prefix(30))...")
                } else if item.type == "file" {
                    print("📄 Öğe \(index + 1): \(item.filename ?? "isimsiz")")
                }
            }
        } catch {
            print("❌ Kayıtlı öğeler yüklenirken hata: \(error)")
        }
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        
        lastChangeCount = pasteboard.changeCount
        print("📋 Pano değişikliği algılandı - changeCount: \(pasteboard.changeCount)")
        
        // Önce metin kontrolü yapalım
        if let text = pasteboard.string(forType: .string) {
            print("✍️ Metin kopyalandı: \(text.prefix(50))...")
            
            let item = ClipboardItem(context: context)
            item.id = UUID()
            item.timestamp = Date()
            item.type = "text"
            
            if let textData = text.data(using: .utf8) {
                print("💾 Metin CoreData'ya kaydediliyor - Boyut: \(textData.count) bytes")
                item.content = textData
                
                clipboardItems.insert(item, at: 0)
                if clipboardItems.count > 50 {
                    context.delete(clipboardItems.removeLast())
                }
                
                CoreDataManager.shared.saveContext()
                print("✅ Metin başarıyla kaydedildi")
            } else {
                print("❌ Metin data'ya dönüştürülemedi")
            }
        }
        // Sonra dosya kontrolü yapalım
        else if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            print("📂 Dosya(lar) kopyalandı: \(urls.count) adet")
            
            for url in urls.reversed() {
                do {
                    let data = try Data(contentsOf: url)
                    print("📄 Dosya okundu: \(url.lastPathComponent) - Boyut: \(data.count) bytes")
                    
                    let item = ClipboardItem(context: context)
                    item.id = UUID()
                    item.timestamp = Date()
                    item.type = "file"
                    item.content = data
                    item.filename = url.lastPathComponent
                    item.fileExtension = url.pathExtension
                    
                    print("💾 Dosya CoreData'ya kaydediliyor: \(url.lastPathComponent)")
                    clipboardItems.insert(item, at: 0)
                } catch {
                    print("❌ Dosya kaydedilirken hata: \(error)")
                }
            }
            
            while clipboardItems.count > 50 {
                if let lastItem = clipboardItems.last {
                    context.delete(lastItem)
                    clipboardItems.removeLast()
                }
            }
            
            CoreDataManager.shared.saveContext()
            print("✅ Tüm dosyalar başarıyla kaydedildi")
            
        } else {
            print("⚠️ Desteklenmeyen içerik türü")
            // Panodaki tüm tipleri göster
            print("📎 Pano içeriği tipleri:")
            for type in pasteboard.types ?? [] {
                print("   - \(type)")
            }
        }
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        timer?.invalidate()
        
        pasteboard.clearContents()
        
        switch item.type {
        case "file":
            if let filename = item.filename,
               let content = item.content {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try? content.write(to: tempURL)
                pasteboard.writeObjects([tempURL as NSURL])
            }
        case "text":
            if let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
        default:
            break
        }
        
        lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    func clearHistory() {
        for item in clipboardItems {
            context.delete(item)
        }
        clipboardItems.removeAll()
        CoreDataManager.shared.saveContext()
    }
}

// Bu struct'ı siliyoruz çünkü artık CoreData entity'si kullanıyoruz
// struct ClipboardItem: Identifiable, Equatable { ... }

// Bu enum'u da artık kullanmıyoruz
// enum ClipboardItemType { ... } 