import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct IsOutfitWornTests {

    @Test func returnsTrueWhenOutfitIsWorn() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        
        #expect(result == true)
    }
    
    @Test func returnsFalseWhenOutfitIsNotWorn() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.isOutfitWorn("pants.avatar", in: "casual")
        
        #expect(result == false)
    }
    
    @Test func returnsFalseWhenCategoryNotInCache() async throws {
        let cache = OutfitCache(categories: [:])
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        
        #expect(result == false)
    }
    
    @Test func returnsFalseWhenCategoryHasNoWornOutfits() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: [], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(category: "casual", files: [], cache: cache)
        
        let result = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        
        #expect(result == false)
    }
    
    @Test func mapsCacheLoadErrorToCacheError() async throws {
        let sut = try makeOutfitPickerSUTWithCacheError(CacheError.decodingFailed)
        
        do {
            _ = try await sut.isOutfitWorn("shirt.avatar", in: "casual")
            Issue.record("Expected cacheError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
