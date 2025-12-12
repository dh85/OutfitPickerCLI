import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct ShowAllWornOutfitsTests {

    @Test func returnsWornOutfitsSortedByCategory() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar", "pants.avatar"], totalOutfits: 3),
                "formal": CategoryCache(wornOutfits: ["suit.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.showAllWornOutfits()
        
        #expect(result["casual"] == ["pants.avatar", "shirt.avatar"])
        #expect(result["formal"] == ["suit.avatar"])
    }
    
    @Test func excludesCategoriesWithNoWornOutfits() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2),
                "formal": CategoryCache(wornOutfits: [], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.showAllWornOutfits()
        
        #expect(result["casual"] == ["shirt.avatar"])
        #expect(result["formal"] == nil)
    }
    
    @Test func returnsEmptyDictionaryWhenNoCategoriesHaveWornOutfits() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: [], totalOutfits: 2),
                "formal": CategoryCache(wornOutfits: [], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.showAllWornOutfits()
        
        #expect(result.isEmpty)
    }
    
    @Test func returnsEmptyDictionaryWhenCacheIsEmpty() async throws {
        let env = try makeSingleCategorySUT(category: "casual", files: [])
        
        let result = try await env.sut.showAllWornOutfits()
        
        #expect(result.isEmpty)
    }
    
    @Test func mapsCacheLoadFailureToCacheError() async throws {
        let sut = try makeOutfitPickerSUTWithCacheError(CacheError.decodingFailed)
        
        do {
            _ = try await sut.showAllWornOutfits()
            Issue.record("Expected cacheError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
