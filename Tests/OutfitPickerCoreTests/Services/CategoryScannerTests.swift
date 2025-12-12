import Testing
import Foundation
@testable import OutfitPickerCore
import OutfitPickerTestSupport

@Suite("CategoryScanner Tests")
struct CategoryScannerTests {
    
    @Test("scanCategories marks excluded categories as userExcluded")
    func scanCategoriesExcluded() async throws {
        let rootURL = URL(filePath: "/test", directoryHint: .isDirectory)
        let casualURL = URL(filePath: "/test/casual", directoryHint: .isDirectory)
        let formalURL = URL(filePath: "/test/formal", directoryHint: .isDirectory)
        
        let fileManager = FakeFileManager(
            .ok([rootURL: [casualURL, formalURL]]),
            directories: [rootURL, casualURL, formalURL]
        )
        let cacheManager = FakeCacheManager()
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.scanCategories(in: "/test", excludedCategories: ["casual"])
        
        let casual = result.first { $0.category.name == "casual" }
        #expect(casual?.state == .userExcluded)
        #expect(casual?.outfitCount == 0)
    }
    
    @Test("scanCategories processes non-excluded categories normally")
    func scanCategoriesNonExcluded() async throws {
        let rootURL = URL(filePath: "/test", directoryHint: .isDirectory)
        let casualURL = URL(filePath: "/test/casual", directoryHint: .isDirectory)
        let outfitURL = URL(filePath: "/test/casual/shirt.avatar", directoryHint: .notDirectory)
        
        let fileManager = FakeFileManager(
            .ok([
                rootURL: [casualURL],
                casualURL: [outfitURL]
            ]),
            directories: [rootURL, casualURL]
        )
        let cacheManager = FakeCacheManager()
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        
        let casual = result.first { $0.category.name == "casual" }
        #expect(casual?.state == .hasOutfits)
        #expect(casual?.outfitCount == 1)
    }
    
    @Test("scanCategories marks empty categories")
    func scanCategoriesEmpty() async throws {
        let rootURL = URL(filePath: "/test", directoryHint: .isDirectory)
        let casualURL = URL(filePath: "/test/casual", directoryHint: .isDirectory)
        
        let fileManager = FakeFileManager(
            .ok([
                rootURL: [casualURL],
                casualURL: []
            ]),
            directories: [rootURL, casualURL]
        )
        let cacheManager = FakeCacheManager()
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        
        let casual = result.first { $0.category.name == "casual" }
        #expect(casual?.state == .empty)
        #expect(casual?.outfitCount == 0)
    }
    
    @Test("scanCategories marks categories with no avatar files")
    func scanCategoriesNoAvatarFiles() async throws {
        let rootURL = URL(filePath: "/test", directoryHint: .isDirectory)
        let casualURL = URL(filePath: "/test/casual", directoryHint: .isDirectory)
        let readmeURL = URL(filePath: "/test/casual/readme.txt", directoryHint: .notDirectory)
        
        let fileManager = FakeFileManager(
            .ok([
                rootURL: [casualURL],
                casualURL: [readmeURL]
            ]),
            directories: [rootURL, casualURL]
        )
        let cacheManager = FakeCacheManager()
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        
        let casual = result.first { $0.category.name == "casual" }
        #expect(casual?.state == .noAvatarFiles)
        #expect(casual?.outfitCount == 0)
    }
    
    @Test("getOutfits returns avatar files only")
    func getOutfits() async throws {
        let casualURL = URL(filePath: "/test/casual", directoryHint: .isDirectory)
        let outfit1URL = URL(filePath: "/test/casual/shirt.avatar", directoryHint: .notDirectory)
        let outfit2URL = URL(filePath: "/test/casual/pants.avatar", directoryHint: .notDirectory)
        let readmeURL = URL(filePath: "/test/casual/readme.txt", directoryHint: .notDirectory)
        
        let fileManager = FakeFileManager(
            .ok([casualURL: [outfit1URL, outfit2URL, readmeURL]]),
            directories: [casualURL]
        )
        let cacheManager = FakeCacheManager()
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.getOutfits(in: "/test/casual")
        
        #expect(result.count == 2)
        #expect(result[0].fileName == "pants.avatar")
        #expect(result[1].fileName == "shirt.avatar")
    }
    
    @Test("scanCategories returns cached data when available")
    func scanCategoriesCacheHit() async throws {
        let categoryInfo = CategoryInfo(
            category: CategoryReference(name: "casual", path: "/test/casual"),
            state: .hasOutfits,
            outfitCount: 5
        )
        let cacheManager = FakeCacheManager(categoryInfoCache: ["/test": [categoryInfo]])
        let fileManager = FakeFileManager(.ok([:]))
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.scanCategories(in: "/test", excludedCategories: [])
        
        #expect(result.count == 1)
        #expect(result[0].category.name == "casual")
        #expect(result[0].outfitCount == 5)
    }
    
    @Test("getOutfits returns cached data when available")
    func getOutfitsCacheHit() async throws {
        let cachedOutfits = [
            FileEntry(filePath: "/test/casual/cached.avatar")
        ]
        let cacheManager = FakeCacheManager(outfitsCache: ["/test/casual": cachedOutfits])
        let fileManager = FakeFileManager(.ok([:]))
        let scanner = CategoryScanner(fileManager: fileManager, cacheManager: cacheManager)
        
        let result = try await scanner.getOutfits(in: "/test/casual")
        
        #expect(result.count == 1)
        #expect(result[0].fileName == "cached.avatar")
    }
}
