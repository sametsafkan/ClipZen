import XCTest
import CoreData
@testable import ClipZen

final class ClipboardManagerTests: XCTestCase {
    var sut: ClipboardManager!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let container = NSPersistentContainer(name: "ClipZenDataModel")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        mockContext = container.viewContext
        sut = ClipboardManager.shared
    }
    
    override func tearDownWithError() throws {
        sut.clearHistory()
        sut = nil
        mockContext = nil
        try super.tearDownWithError()
    }
    
    func testAddTextItem() throws {
        // Given
        let testText = "Test metin"
        let expectation = XCTestExpectation(description: "Text item added")
        
        // When
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.sut.clipboardItems.count, 1)
            XCTAssertEqual(self.sut.clipboardItems.first?.type, "text")
            if let content = self.sut.clipboardItems.first?.content,
               let text = String(data: content, encoding: .utf8) {
                XCTAssertEqual(text, testText)
            } else {
                XCTFail("Metin içeriği okunamadı")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testAddFileItem() throws {
        // Given
        let testFilename = "test.txt"
        let testData = "Test içerik".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(testFilename)
        try testData.write(to: tempURL)
        let expectation = XCTestExpectation(description: "File item added")
        
        // When
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([tempURL as NSURL])
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.sut.clipboardItems.count, 1)
            XCTAssertEqual(self.sut.clipboardItems.first?.type, "file")
            XCTAssertEqual(self.sut.clipboardItems.first?.filename, testFilename)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeleteItem() throws {
        // Given
        let testText = "Test"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // Wait for item to be added
        let addExpectation = XCTestExpectation(description: "Item added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.sut.clipboardItems.count, 1)
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 2.0)
        
        // When
        if let item = sut.clipboardItems.first {
            sut.deleteItem(item)
        }
        
        // Then
        XCTAssertEqual(sut.clipboardItems.count, 0)
    }
    
    func testClearHistory() throws {
        // Given
        let testText = "Test"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // Wait for first item
        let firstExpectation = XCTestExpectation(description: "First item added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pasteboard.setString(testText + "2", forType: .string)
            firstExpectation.fulfill()
        }
        wait(for: [firstExpectation], timeout: 2.0)
        
        // Wait for second item
        let secondExpectation = XCTestExpectation(description: "Second item added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.sut.clipboardItems.count, 2)
            secondExpectation.fulfill()
        }
        wait(for: [secondExpectation], timeout: 2.0)
        
        // When
        sut.clearHistory()
        
        // Then
        XCTAssertEqual(sut.clipboardItems.count, 0)
    }
} 