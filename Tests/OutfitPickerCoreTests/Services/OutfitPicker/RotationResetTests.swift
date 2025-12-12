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

    // MARK: - partialReset

    @Test
    func partialReset_guardWhenWornCountAtLeastTotal_doesNothing() async throws {
        let existingCache = OutfitCache(categories: [
            "DateNight": CategoryCache(
                wornOutfits: ["one.avatar", "two.avatar"],
                totalOutfits: 2
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "DateNight",
            files: ["one.avatar", "two.avatar"],
            cache: existingCache
        )

        try await env.sut.partialReset(categoryName: "DateNight", wornCount: 2)
        #expect(env.cache.saved.isEmpty)  // guard fails → early success, no save
    }

    @Test
    func partialReset_withSmallerWornCount_truncatesWornSet() async throws {
        let files = ["one.avatar", "two.avatar", "three.avatar"]
        let existingCache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: Set(files),
                totalOutfits: 3
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Chic",
            files: files,
            cache: existingCache
        )

        try await env.sut.partialReset(categoryName: "Chic", wornCount: 1)

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories["Chic"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.count == 1)
    }

    @Test
    func partialReset_forCategoryWithoutExistingCache_stillWritesCache() async throws {
        let files = ["x.avatar", "y.avatar"]
        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Latex",
            files: files,
            cache: OutfitCache()  // no entry for "Latex"
        )

        try await env.sut.partialReset(categoryName: "Latex", wornCount: 0)

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories["Latex"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.isEmpty)
    }

    @Test func partialReset_configLoadFailure_mapsToInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        do {
            try await sut.partialReset(categoryName: "Any", wornCount: 1)
            Issue.record("Expected invalidConfiguration when config load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
