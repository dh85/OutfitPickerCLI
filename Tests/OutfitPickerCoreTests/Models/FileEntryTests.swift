import Testing
import Foundation
@testable import OutfitPickerCore

@Suite("FileEntry Tests")
struct FileEntryTests {
    
    @Test("fileName extracts file name from path")
    func fileName() {
        let entry = FileEntry(filePath: "/test/casual/shirt.avatar")
        
        #expect(entry.fileName == "shirt.avatar")
    }
    
    @Test("categoryPath returns category directory path")
    func categoryPath() {
        let entry = FileEntry(filePath: "/test/casual/shirt.avatar")
        
        #expect(entry.categoryPath == "/test/casual/")
    }
    
    @Test("categoryName returns category directory name")
    func categoryName() {
        let entry = FileEntry(filePath: "/test/casual/shirt.avatar")
        
        #expect(entry.categoryName == "casual")
    }
    
    @Test("handles nested category paths")
    func nestedPaths() {
        let entry = FileEntry(filePath: "/home/user/outfits/formal/suit.avatar")
        
        #expect(entry.fileName == "suit.avatar")
        #expect(entry.categoryPath == "/home/user/outfits/formal/")
        #expect(entry.categoryName == "formal")
    }
    
    @Test("equatable compares file paths")
    func equatable() {
        let entry1 = FileEntry(filePath: "/test/casual/shirt.avatar")
        let entry2 = FileEntry(filePath: "/test/casual/shirt.avatar")
        let entry3 = FileEntry(filePath: "/test/formal/suit.avatar")
        
        #expect(entry1 == entry2)
        #expect(entry1 != entry3)
    }
}
