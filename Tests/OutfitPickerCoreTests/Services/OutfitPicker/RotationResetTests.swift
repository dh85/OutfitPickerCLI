import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct RotationResetTests {

    private let root = "/Users/test/Outfits"

    // MARK: - resetCategory

    @Test
    func resetCategory_resetsNamedCategoryAndPreservesOthers() async throws {
        let initialCache = OutfitCache(categories: [
            "Casual": CategoryCache(
                wornOutfits: ["c1.avatar", "c2.avatar"],
                totalOutfits: 5
            ),
            "Club": CategoryCache(
                wornOutfits: ["club1.avatar"],
                totalOutfits: 3
            ),
        ])

        let env = try makeOutfitPickerSUT(root: root, cache: initialCache)
        try await env.sut.resetCategory("Casual")

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)

        #expect(saved.categories["Casual"] == nil)  // Category removed from cache

        let club = try #require(saved.categories["Club"])
        #expect(club.totalOutfits == 3)
        #expect(club.wornOutfits == ["club1.avatar"])
    }

    @Test
    func resetCategory_configLoadFailure_mapsToInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        do {
            try await sut.resetCategory("Any")
            Issue.record("Expected invalidConfiguration when config load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test
    func resetCategory_cacheLoadFailure_mapsToCacheError() async throws {
        let sut = try makeOutfitPickerSUTWithCacheError(
            CacheError.decodingFailed
        )

        do {
            try await sut.resetCategory("Casual")
            Issue.record("Expected cacheError when cache load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    // MARK: - resetAllCategories

    @Test
    func resetAllCategories_replacesCacheWithEmpty() async throws {
        let existing = OutfitCache(categories: [
            "A": CategoryCache(wornOutfits: ["a1"], totalOutfits: 2),
            "B": CategoryCache(wornOutfits: ["b1", "b2"], totalOutfits: 3),
        ])

        let env = try makeOutfitPickerSUT(root: root, cache: existing)
        try await env.sut.resetAllCategories()

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        #expect(saved.categories.isEmpty)
    }

    @Test
    func resetAllCategories_configLoadFailure_mapsToInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )

        do {
            try await sut.resetAllCategories()
            Issue.record("Expected invalidConfiguration when config load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }


}
