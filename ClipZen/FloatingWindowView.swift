import SwiftUI

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
    
    var body: some View {
        HStack {
            switch item.type {
            case .text:
                if let text = item.content as? String {
                    Text(text)
                        .lineLimit(2)
                }
            case .image:
                if let imageData = item.content as? Data,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                }
            }
            
            Spacer()
            
            Text(item.timestamp, style: .time)
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
} 