import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct RandomOutfitAcrossCategoriesTests {

    private let root = "/Users/test/Outfits"

    @Test func across_returnsNil_whenNoCategoriesAtRoot() async throws {
        let env = try makeOutfitPickerSUT(root: root)
        let value = try await env.sut.showRandomOutfitAcrossCategories()
        #expect(value == nil)
    }

    @Test func across_skipsExcludedEmptyAndNoAvatar_selectsFromAvailable() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "Excluded": ["ex.avatar"],
                "Empty": [],
                "NoAvatar": ["readme.txt"],
                "Good": ["g1.avatar", "g2.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            config: try Config(
                root: root,
                language: "en",
                excludedCategories: ["Excluded"]
            ),
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let ref = try await env.sut.showRandomOutfitAcrossCategories()

        #expect(ref!.category.name == "Good")
        #expect(["g1.avatar", "g2.avatar"].contains(ref!.fileName))
    }

    @Test func across_respectsWornPerCategory_onlyUnwornAddedToPool() async throws {
        // Good has two avatars; one already worn → must pick the other
        let cache = OutfitCache(categories: [
            "Good": CategoryCache(
                wornOutfits: ["g1.avatar"],
                totalOutfits: 2
            )
        ])

        let fs = makeFS(
            root: root,
            categories: ["Good": ["g1.avatar", "g2.avatar"]]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            cache: cache,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let ref = try await env.sut.showRandomOutfitAcrossCategories()

        #expect(ref!.category.name == "Good")
        #expect(ref!.fileName == "g2.avatar")
    }

    @Test func across_returnsNil_whenAllCategoriesFullyWorn() async throws {
        let cache = OutfitCache(categories: [
            "A": CategoryCache(
                wornOutfits: ["a1.avatar"],
                totalOutfits: 1
            ),
            "B": CategoryCache(
                wornOutfits: ["b1.avatar"],
                totalOutfits: 1
            ),
        ])

        let fs = makeFS(
            root: root,
            categories: [
                "A": ["a1.avatar"],
                "B": ["b1.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            cache: cache,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let value = try await env.sut.showRandomOutfitAcrossCategories()
        #expect(value == nil)
    }

    @Test func across_picksFromMultipleCategories_whenAvailable() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "A": ["a1.avatar"],
                "B": ["b1.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let ref = try await env.sut.showRandomOutfitAcrossCategories()

        #expect(["A", "B"].contains(ref!.category.name))
        #expect(["a1.avatar", "b1.avatar"].contains(ref!.fileName))
    }

    @Test func across_noSaveWhenNoResetNeeded() async throws {
        let fs = makeFS(
            root: root,
            categories: ["Solo": ["s1.avatar"]]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let value = try await env.sut.showRandomOutfitAcrossCategories()
        #expect(value?.fileName == "s1.avatar")
        #expect(value?.category.name == "Solo")
        #expect(env.cache.saved.isEmpty)
    }

    @Test func across_failure_configLoad_mapsToInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )

        do {
            _ = try await sut.showRandomOutfitAcrossCategories()
            Issue.record("Expected invalidConfiguration")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func across_failure_rootListing_mapsToFileSystemError() async throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )

        do {
            _ = try await sut.showRandomOutfitAcrossCategories()
            Issue.record("Expected fileSystemError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func across_failure_cacheLoad_mapsToCacheError() async throws {
        let fs = makeFS(root: root, categories: ["Good": ["g1.avatar"]])
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(
            .throwsOnLoad(CacheError.decodingFailed)
        )
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        do {
            _ = try await sut.showRandomOutfitAcrossCategories()
            Issue.record("Expected cacheError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
