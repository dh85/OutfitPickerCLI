import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct WearOutfitTests {

    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Happy-path behaviour

    @Test func wear_addsOutfitToNewCategoryCache_andSavesOnce() async throws {
        let categoryName = "Chic"
        let fileName = "one.avatar"

        let env = try makeSingleCategorySUT(
            category: categoryName,
            files: [fileName, "two.avatar"]  // 2 outfits so wearing 1 doesn't complete rotation
        )

        let ref = makeOutfitReference(
            root: safeRoot,
            category: categoryName,
            fileName: fileName
        )

        try await env.sut.wearOutfit(ref)

        // One save
        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories[categoryName])

        #expect(cat.wornOutfits == [fileName])
        #expect(cat.totalOutfits == 2)
    }

    @Test func wear_completesRotationAndResets_whenLastOutfitWorn() async throws {
        let categoryName = "Complete"
        let file1 = "one.avatar"
        let file2 = "two.avatar"

        // Start with 1 of 2 worn
        let cache = OutfitCache(categories: [
            categoryName: CategoryCache(
                wornOutfits: [file1],
                totalOutfits: 2
            )
        ])

        let env = try makeSingleCategorySUT(
            category: categoryName,
            files: [file1, file2],
            cache: cache
        )

        let ref = makeOutfitReference(
            root: safeRoot,
            category: categoryName,
            fileName: file2
        )

        // When wearing the last unworn outfit
        do {
            try await env.sut.wearOutfit(ref)
            Issue.record("Expected rotationCompleted error")
        } catch OutfitPickerError.rotationCompleted(let category) {
            // Then - should throw rotationCompleted and reset the category
            #expect(category == categoryName)
            #expect(env.cache.saved.count == 1)
            let saved = try #require(env.cache.saved.first)
            let cat = saved.categories[categoryName]
            #expect(cat?.wornOutfits.isEmpty == true)
            #expect(cat?.totalOutfits == 2)
        } catch {
            Issue.record("Expected rotationCompleted error, got \(error)")
        }
    }

    @Test func wear_doesNotSave_whenOutfitAlreadyMarkedAsWorn() async throws {
        let categoryName = "Club"
        let fileName = "track.avatar"

        let cache = OutfitCache(categories: [
            categoryName: CategoryCache(
                wornOutfits: [fileName],
                totalOutfits: 1
            )
        ])

        let env = try makeSingleCategorySUT(
            category: categoryName,
            files: [fileName],
            cache: cache
        )

        let ref = makeOutfitReference(
            root: safeRoot,
            category: categoryName,
            fileName: fileName
        )

        try await env.sut.wearOutfit(ref)

        // No additional save should occur
        #expect(env.cache.saved.isEmpty)
    }

    // MARK: - Error mapping

    @Test func wear_failure_configLoad_mapsToInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )
        let ref = makeOutfitReference(
            root: safeRoot,
            category: "Any",
            fileName: "any.avatar"
        )

        do {
            try await sut.wearOutfit(ref)
            Issue.record("Expected invalidConfiguration from wearOutfit when config load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func wear_failure_avatarListing_mapsToFileSystemError() async throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )
        let ref = makeOutfitReference(
            root: safeRoot,
            category: "Any",
            fileName: "any.avatar"
        )

        do {
            try await sut.wearOutfit(ref)
            Issue.record("Expected fileSystemError from wearOutfit when FileManager throws.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func wear_failure_cacheLoad_mapsToCacheError() async throws {
        let sut = try makeOutfitPickerSUTWithCacheError(
            CacheError.decodingFailed
        )
        let ref = makeOutfitReference(
            root: safeRoot,
            category: "Any",
            fileName: "any.avatar"
        )

        do {
            try await sut.wearOutfit(ref)
            Issue.record("Expected cacheError from wearOutfit when cache load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
