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
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label {
                    Text(localizationManager.localizedString(for: "clipboard_history"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "doc.on.clipboard")
                        .imageScale(.medium)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(localizationManager.localizedString(for: "search"),
                         text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(height: 24)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Clipboard Items List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        ClipboardItemView(item: item)
                            .environmentObject(clipboardManager)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Footer
            HStack {
                Text(localizationManager.localizedString(for: "items_count", filteredItems.count))
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Spacer()
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Label {
                        Text(localizationManager.localizedString(for: "clear_history"))
                            .foregroundStyle(.red)
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.8)
                
                if themeMode.colorScheme == .dark {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color(nsColor: .windowBackgroundColor).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert(
            localizationManager.localizedString(for: "clear_history"),
            isPresented: $showingClearAlert
        ) {
            Button(localizationManager.localizedString(for: "delete"), role: .destructive) {
                withAnimation(.easeInOut) {
                    clipboardManager.clearHistory()
                }
            }
            Button(localizationManager.localizedString(for: "cancel"), role: .cancel) {}
        } message: {
            Text(localizationManager.localizedString(for: "clear_history_message"))
        }
        .frame(width: 400, height: 500)
        .opacity(opacity)
        .preferredColorScheme(themeMode.colorScheme)
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .id("floating_window_content_\(localizationManager.currentLanguage.rawValue)")
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
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var clipboardManager: ClipboardManager
    
    var itemType: ClipboardItemType {
        ClipboardItemType(rawValue: item.type ?? "") ?? .text
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // İkon
            Group {
                if item.type == "text" {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)
                } else if item.type == "file" {
                    Image(systemName: getSystemImage(for: item.fileExtension ?? ""))
                        .foregroundStyle(getIconColor(for: item.fileExtension ?? ""))
                }
            }
            .font(.title2)
            .frame(width: 24, height: 24)
            
            // İçerik
            if item.type == "text",
               let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                Text(text)
                    .lineLimit(2)
                    .truncationMode(.tail)
            } else if item.type == "file" {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.filename ?? "Dosya")
                        .lineLimit(1)
                    if let ext = item.fileExtension {
                        Text(ext.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Butonlar
            HStack(spacing: 12) {
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
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.copyToPasteboard(item)
            dismiss()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.01))
        .cornerRadius(6)
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
            return "music.note.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func getIconColor(for fileExtension: String) -> Color {
        switch fileExtension.lowercased() {
        case "pdf":
            return .red
        case "txt", "rtf", "md":
            return .blue
        case "jpg", "jpeg", "png", "gif", "heic":
            return .green
        case "mp4", "mov", "avi":
            return .purple
        case "mp3", "wav", "m4a":
            return .pink
        default:
            return .gray
        }
    }
}

struct SearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = placeholder
        searchField.delegate = context.coordinator
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
        nsView.placeholderString = placeholder
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let searchField = obj.object as? NSSearchField {
                text = searchField.stringValue
            }
        }
    }
}
