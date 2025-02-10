import CoreData
import AppKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let containerName = "ClipZenDataModel"
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Model dosyasının URL'sini bul
        guard let modelURL = Bundle.main.url(forResource: containerName, withExtension: "momd") else {
            fatalError("❌ Core Data model dosyası bulunamadı: \(containerName).momd")
        }
        
        // Model nesnesini oluştur
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("❌ Core Data model yüklenemedi: \(modelURL)")
        }
        
        print("📦 Core Data model yüklendi")
        
        // Container'ı oluştur
        let container = NSPersistentContainer(name: containerName, managedObjectModel: model)
        
        // SQLite dosyasının konumunu ayarla
        let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = storeDirectory.appendingPathComponent("\(containerName).sqlite")
        print("💽 Veritabanı konumu: \(url.path)")
        
        let description = NSPersistentStoreDescription(url: url)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data yüklenirken hata: \(error)")
                print("🔍 Hata detayı: \(error.localizedDescription)")
            } else {
                print("✅ Core Data başarıyla yüklendi")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        print("🚀 CoreDataManager başlatılıyor...")
        // Application Support dizinini oluştur
        let fileManager = FileManager.default
        if let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                print("📁 Application Support dizini oluşturuldu: \(url.path)")
            } catch {
                print("❌ Dizin oluşturulurken hata: \(error)")
            }
        }
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("💾 Core Data değişiklikleri kaydedildi")
            } catch {
                print("❌ Core Data kaydedilirken hata: \(error)")
                print("🔍 Hata detayı: \(error.localizedDescription)")
            }
        }
    }
} 