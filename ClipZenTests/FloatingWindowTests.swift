import XCTest
import SwiftUI
@testable import ClipZen

final class FloatingWindowTests: XCTestCase {
    var sut: FloatingWindow!
    var clipboardManager: ClipboardManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        clipboardManager = ClipboardManager.shared
        sut = FloatingWindow()
    }
    
    override func tearDownWithError() throws {
        clipboardManager.clearHistory()
        clipboardManager = nil
        sut = nil
        try super.tearDownWithError()
    }
    
    func testSearchFiltering() throws {
        // Given
        let testText = "Özel test metni"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // Biraz bekle
        Thread.sleep(forTimeInterval: 1.0)
        
        // When
        let searchText = "özel"
        if let searchBinding = Mirror(reflecting: sut).children
            .first(where: { $0.label == "searchText" })?
            .value as? Binding<String> {
            searchBinding.wrappedValue = searchText
        }
        
        // Then
        let items = clipboardManager.clipboardItems.filter { item in
            if let content = item.content,
               let text = String(data: content, encoding: .utf8) {
                return text.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
        XCTAssertEqual(items.count, 1)
    }
} 