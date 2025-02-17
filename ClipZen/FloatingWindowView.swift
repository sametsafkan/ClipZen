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
                }
            }
        }
        .frame(width: 400, height: 500)
        .opacity(windowOpacity)
    }
}
/*
struct ClipboardItemRowView: View {
    let item: ClipboardItem
    let clipboardManager: ClipboardManager
    @State private var thumbnail: NSImage?
    
    var body: some View {
        HStack {
            // İçerik gösterimi
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
                            Image(systemName: "doc")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                        }
                        
                        Text(filename)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .onAppear {
                        loadThumbnail()
                    }
                }
            case "text":
                if let content = item.content,
                   let text = String(data: content, encoding: .utf8) {
                    Text(text)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Butonlar
            HStack(spacing: 12) {
                // Kopyala butonu
                Button(action: {
                    clipboardManager.copyToPasteboard(item)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Panoya Kopyala")
                
                // Sil butonu
                Button(action: {
                    clipboardManager.deleteItem(item)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Sil")
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.copyToPasteboard(item)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.01))
        .cornerRadius(6)
    }
    
    private func loadThumbnail() {
        guard let filename = item.filename,
              let content = item.content else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: tempURL)
        
        if let imageSource = CGImageSourceCreateWithURL(tempURL as CFURL, nil),
           let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, nil) {
            self.thumbnail = NSImage(cgImage: thumbnail, size: NSSize(width: 40, height: 40))
        }
        
        try? FileManager.default.removeItem(at: tempURL)
    }
}*/


struct ClipboardItemRowView: View {
    let item: ClipboardItem
    @State private var thumbnail: NSImage?
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            // Mevcut içerik gösterimi
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
            
            // Sağ taraftaki butonlar ve zaman
            HStack(spacing: 12) {
                if let timestamp = item.timestamp {
                    Text(timestamp, style: .time)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                // Kopyala butonu
                Button(action: {
                    clipboardManager.copyToPasteboard(item)
                    dismiss()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Panoya Kopyala")
                
                // Sil butonu
                Button(action: {
                    clipboardManager.deleteItem(item)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Sil")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.copyToPasteboard(item)
            dismiss()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.01))
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
