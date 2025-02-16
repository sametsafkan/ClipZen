import SwiftUI

enum ClipboardItemType: String {
    case text = "text"
    case image = "image"
    case pdf = "pdf"
    case file = "file"
    
    var icon: Image {
        switch self {
        case .text:
            return Image(systemName: "doc.text")
        case .image:
            return Image(systemName: "photo")
        case .pdf:
            return Image(systemName: "doc.fill")
        case .file:
            return Image(systemName: "doc")
        }
    }
    
    var color: Color {
        switch self {
        case .text:
            return .green
        case .image:
            return .blue
        case .pdf:
            return .red
        case .file:
            return .orange
        }
    }
} 