import Foundation
import Testing
@testable import OutfitPickerCore

@Suite
struct CacheManagerTests {
    
    @Test func cachesCategoryInfo() async throws {
        let cacheManager = CacheManager()
        let categoryInfo = CategoryInfo(
            category: CategoryReference(name: "Test", path: "/test"),
            state: .hasOutfits,
            outfitCount: 1
        )
        
        await cacheManager.setCachedCategoryInfo([categoryInfo], for: "/root")
        let cached = await cacheManager.getCachedCategoryInfo(for: "/root")
        
        #expect(cached?.count == 1)
        #expect(cached?.first?.category.name == "Test")
    }
    
    @Test func cachesOutfits() async throws {
        let cacheManager = CacheManager()
        let outfit = FileEntry(filePath: "/test/outfit.avatar")
        
        await cacheManager.setCachedOutfits([outfit], for: "/test")
        let cached = await cacheManager.getCachedOutfits(for: "/test")
        
        #expect(cached?.count == 1)
        #expect(cached?.first?.fileName == "outfit.avatar")
    }
    
    @Test func invalidatesCacheCorrectly() async throws {
        let cacheManager = CacheManager()
        let categoryInfo = CategoryInfo(
            category: CategoryReference(name: "Test", path: "/test"),
            state: .hasOutfits,
            outfitCount: 1
        )
        let outfit = FileEntry(filePath: "/test/outfit.avatar")
        
        await cacheManager.setCachedCategoryInfo([categoryInfo], for: "/root")
        await cacheManager.setCachedOutfits([outfit], for: "/test")
        await cacheManager.invalidateCache()
        
        let cachedInfo = await cacheManager.getCachedCategoryInfo(for: "/root")
        let cachedOutfits = await cacheManager.getCachedOutfits(for: "/test")
        
        #expect(cachedInfo == nil)
        #expect(cachedOutfits == nil)
    }
}