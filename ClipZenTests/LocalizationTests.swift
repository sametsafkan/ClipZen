import XCTest
@testable import ClipZen

final class LocalizationTests: XCTestCase {
    var sut: LocalizationManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = LocalizationManager.shared
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testLanguageChange() throws {
        // Given
        let initialLanguage = sut.currentLanguage
        let newLanguage = Language.english
        
        // When
        sut.setLanguage(newLanguage)
        
        // Then
        XCTAssertEqual(sut.currentLanguage, newLanguage)
        XCTAssertNotEqual(sut.currentLanguage, initialLanguage)
    }
    
    func testLocalizationStrings() throws {
        // Test various languages
        for language in Language.allCases {
            sut.setLanguage(language)
            
            // Test common strings
            XCTAssertFalse(sut.localizedString(for: "ok").isEmpty)
            XCTAssertFalse(sut.localizedString(for: "cancel").isEmpty)
            XCTAssertFalse(sut.localizedString(for: "settings").isEmpty)
        }
    }
} 