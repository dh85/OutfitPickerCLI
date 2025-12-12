import Testing
import Foundation
@testable import OutfitPickerCore

@Suite("OutfitSelection Tests")
struct OutfitSelectionTests {
    
    @Test("selectRandom returns outfit from pool")
    func selectRandomFromPool() {
        let pool = [
            FileEntry(filePath: "/test/outfit1.avatar"),
            FileEntry(filePath: "/test/outfit2.avatar")
        ]
        
        let result = OutfitSelection.selectRandom(from: pool)
        
        #expect(result != nil)
        #expect(pool.contains(result!))
    }
    
    @Test("selectRandom returns nil for empty pool")
    func selectRandomEmptyPool() {
        let result = OutfitSelection.selectRandom(from: [])
        
        #expect(result == nil)
    }
    
    @Test("selectRandomCategory returns category and outfit")
    func selectRandomCategory() {
        let categories = [
            ("casual", [FileEntry(filePath: "/test/casual/shirt.avatar")]),
            ("formal", [FileEntry(filePath: "/test/formal/suit.avatar")])
        ]
        
        let result = OutfitSelection.selectRandomCategory(from: categories)
        
        #expect(result != nil)
        #expect(result?.0 == "casual" || result?.0 == "formal")
    }
    
    @Test("selectRandomCategory returns nil for empty categories")
    func selectRandomCategoryEmpty() {
        let result = OutfitSelection.selectRandomCategory(from: [])
        
        #expect(result == nil)
    }
    
    @Test("selectRandomCategory returns nil when category has no files")
    func selectRandomCategoryNoFiles() {
        let categories = [("casual", [FileEntry]())]
        
        let result = OutfitSelection.selectRandomCategory(from: categories)
        
        #expect(result == nil)
    }
}
