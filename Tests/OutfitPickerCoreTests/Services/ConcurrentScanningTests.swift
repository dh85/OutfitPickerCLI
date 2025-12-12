import Foundation
import OutfitPickerTestSupport
import Testing
@testable import OutfitPickerCore

@Suite
struct ConcurrentScanningTests {
    
    @Test func concurrentScanning_processesMultipleCategories() async throws {
        // Create test data with multiple categories
        let categories = [
            "Category1": ["outfit1.avatar", "outfit2.avatar"],
            "Category2": ["outfit3.avatar", "outfit4.avatar"],
            "Category3": ["outfit5.avatar", "outfit6.avatar"]
        ]
        
        let fs = makeFS(root: "/test", categories: categories)
        let fileManager = FakeFileManager(.ok(fs.contents), directories: Array(fs.directories))
        let cacheManager = CacheManager()
        
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        // Test concurrent scanning
        let startTime = Date()
        let categoryInfos = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        let endTime = Date()
        
        // Verify results
        #expect(categoryInfos.count == 3)
        #expect(categoryInfos.allSatisfy { $0.state == CategoryState.hasOutfits })
        #expect(categoryInfos.allSatisfy { $0.outfitCount == 2 })
        
        // Performance should be reasonable (this is more of a smoke test)
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0) // Should complete within 1 second
    }
    
    @Test func concurrentScanning_handlesEmptyCategories() async throws {
        let categories = [
            "HasOutfits": ["outfit1.avatar"],
            "Empty": [],
            "NoAvatar": ["readme.txt"]
        ]
        
        let fs = makeFS(root: "/test", categories: categories)
        let fileManager = FakeFileManager(.ok(fs.contents), directories: Array(fs.directories))
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: CacheManager())
        
        let categoryInfos = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        
        #expect(categoryInfos.count == 3)
        
        let hasOutfits = categoryInfos.first { $0.category.name == "HasOutfits" }
        #expect(hasOutfits?.state == CategoryState.hasOutfits)
        #expect(hasOutfits?.outfitCount == 1)
        
        let empty = categoryInfos.first { $0.category.name == "Empty" }
        #expect(empty?.state == CategoryState.empty)
        #expect(empty?.outfitCount == 0)
        
        let noAvatar = categoryInfos.first { $0.category.name == "NoAvatar" }
        #expect(noAvatar?.state == CategoryState.noAvatarFiles)
        #expect(noAvatar?.outfitCount == 0)
    }
}