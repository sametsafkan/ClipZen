import SwiftUI
import Quartz
import UniformTypeIdentifiers

struct FloatingWindowView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @AppStorage("windowOpacity") private var windowOpacity = 0.9
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            List {
                ForEach(clipboardManager.clipboardItems) { item in
                    ClipboardItemRowView(item: item)
                        .onTapGesture {
                            clipboardManager.copyToPasteboard(item)
                            dismiss()
                        }
                }
            }
        }
        .frame(width: 400, height: 500)
        .opacity(windowOpacity)
    }
}

struct ClipboardItemRowView: View {
    let item: ClipboardItem
    @State private var thumbnail: NSImage?
    
    var body: some View {
        HStack {
            switch item.type {
            case "file":
                if let filename = item.filename {
                    HStack {
                        // Önizleme görüntüsü
                        if let thumbnail = thumbnail {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        } else {
                            // Varsayılan dosya ikonu
                            Label(filename, systemImage: getSystemImage(for: item.fileExtension ?? ""))
                                .frame(width: 40, height: 40)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(filename)
                                .lineLimit(1)
                            if let ext = item.fileExtension {
                                Text(ext.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            case "text":
                if let content = item.content,
                   let text = String(data: content, encoding: .utf8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .frame(width: 40)
                        
                        Text(text)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            default:
                EmptyView()
            }
            
            Spacer()
            
            if let timestamp = item.timestamp {
                Text(timestamp, style: .time)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if item.type == "file" {
                generateThumbnail()
            }
        }
    }
    
    private func generateThumbnail() {
        // Geçici dosya oluştur
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(item.filename ?? "temp")
        try? item.content!.write(to: tempURL)
        
        // Quartz ile önizleme oluştur
        let iconRef = NSWorkspace.shared.icon(forFile: tempURL.path)
        DispatchQueue.main.async {
            self.thumbnail = iconRef
        }
        
        // Geçici dosyayı temizle
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    private func getSystemImage(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "doc.fill"
        case "txt", "rtf", "md":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo.fill"
        case "mp4", "mov", "avi":
            return "film.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        default:
            return "doc.fill"
        }
    }
} 
