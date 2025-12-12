import Foundation
import Testing
@testable import OutfitPickerCore

@Suite
struct CategoryCachePerformanceTests {
    
    @Test func adding_duplicateOutfit_returnsOriginalInstance() {
        let cache = CategoryCache(
            wornOutfits: ["outfit1.avatar", "outfit2.avatar"],
            totalOutfits: 10
        )
        
        let result = cache.adding("outfit1.avatar")
        
        // Should return the same instance for efficiency
        #expect(result.wornOutfits == cache.wornOutfits)
        #expect(result.totalOutfits == cache.totalOutfits)
    }
    
    @Test func updating_sameCache_returnsOriginalInstance() {
        let categoryCache = CategoryCache(wornOutfits: ["outfit1.avatar"], totalOutfits: 5)
        let outfitCache = OutfitCache(categories: ["casual": categoryCache])
        
        let result = outfitCache.updating(category: "casual", with: categoryCache)
        
        // Should return the same instance when no change is needed
        #expect(result.categories == outfitCache.categories)
    }
    
    @Test func removing_nonExistentCategory_returnsOriginalInstance() {
        let outfitCache = OutfitCache(categories: ["casual": CategoryCache(totalOutfits: 5)])
        
        let result = outfitCache.removing(category: "formal")
        
        // Should return the same instance when category doesn't exist
        #expect(result.categories == outfitCache.categories)
    }
    
    @Test func adding_newOutfit_createsNewInstanceEfficiently() {
        let cache = CategoryCache(
            wornOutfits: ["outfit1.avatar"],
            totalOutfits: 10
        )
        
        let result = cache.adding("outfit2.avatar")
        
        #expect(result.wornOutfits.count == 2)
        #expect(result.wornOutfits.contains("outfit1.avatar"))
        #expect(result.wornOutfits.contains("outfit2.avatar"))
        #expect(result.totalOutfits == cache.totalOutfits)
    }
}