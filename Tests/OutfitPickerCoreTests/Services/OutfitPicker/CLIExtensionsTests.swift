import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct CLIExtensionsTests {

    @Test func getAvailableOutfitsReturnsUnwornOutfits() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 3)
            ]
        )
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar", "jacket.avatar"],
            cache: cache
        )

        let result = try await env.sut.getAvailableOutfits(from: "casual")

        #expect(result.count == 2)
        #expect(result.contains { $0.fileName == "pants.avatar" })
        #expect(result.contains { $0.fileName == "jacket.avatar" })
    }

    @Test func getWornOutfitsReturnsWornOutfits() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(
                    wornOutfits: ["shirt.avatar", "pants.avatar"], totalOutfits: 3)
            ]
        )
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar", "jacket.avatar"],
            cache: cache
        )

        let result = try await env.sut.getWornOutfits(from: "casual")

        #expect(result.count == 2)
        #expect(result.contains { $0.fileName == "shirt.avatar" })
        #expect(result.contains { $0.fileName == "pants.avatar" })
    }

    @Test func getOutfitStateReturnsCompleteState() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar"],
            cache: cache
        )

        let result = try await env.sut.getOutfitState(for: "casual")

        #expect(result.category.name == "casual")
        #expect(result.totalCount == 2)
        #expect(result.wornCount == 1)
        #expect(result.availableCount == 1)
    }

    @Test func getOutfitStateThrowsForNonexistentCategory() async throws {
        let env = try makeSingleCategorySUT(category: "casual", files: ["shirt.avatar"])

        await #expect(throws: OutfitPickerError.self) {
            _ = try await env.sut.getOutfitState(for: "nonexistent")
        }
    }

    @Test func getAllOutfitStatesReturnsAllCategories() async throws {
        let root = "/test"
        let casualURL = URL(filePath: "\(root)/casual", directoryHint: .isDirectory)
        let formalURL = URL(filePath: "\(root)/formal", directoryHint: .isDirectory)

        let categoryInfos = [
            CategoryInfo(
                category: CategoryReference(
                    name: "casual", path: casualURL.path(percentEncoded: false)),
                state: .hasOutfits,
                outfitCount: 1
            ),
            CategoryInfo(
                category: CategoryReference(
                    name: "formal", path: formalURL.path(percentEncoded: false)),
                state: .hasOutfits,
                outfitCount: 1
            ),
        ]

        let outfitsByPath = [
            casualURL.path(percentEncoded: false): [
                FileEntry(filePath: "\(casualURL.path(percentEncoded: false))/shirt.avatar")
            ],
            formalURL.path(percentEncoded: false): [
                FileEntry(filePath: "\(formalURL.path(percentEncoded: false))/suit.avatar")
            ],
        ]

        let config = try Config(root: root, language: "en")
        let categoryRepository = FakeCategoryRepository(
            categoryInfos: categoryInfos, outfitsByPath: outfitsByPath)
        let sut = OutfitPicker(
            config: config,
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: categoryRepository
        )

        let result = try await sut.getAllOutfitStates()

        #expect(result.count == 2)
        #expect(result["casual"] != nil)
        #expect(result["formal"] != nil)
    }

    @Test func getAllAvailableOutfitsWithKeysReturnsSortedResults() async throws {
        let root = "/test"
        let casualURL = URL(filePath: "\(root)/casual", directoryHint: .isDirectory)

        let categoryInfos = [
            CategoryInfo(
                category: CategoryReference(
                    name: "casual", path: casualURL.path(percentEncoded: false)),
                state: .hasOutfits,
                outfitCount: 2
            )
        ]

        let outfitsByPath = [
            casualURL.path(percentEncoded: false): [
                FileEntry(filePath: "\(casualURL.path(percentEncoded: false))/z.avatar"),
                FileEntry(filePath: "\(casualURL.path(percentEncoded: false))/a.avatar"),
            ]
        ]

        let config = try Config(root: root, language: "en")
        let categoryRepository = FakeCategoryRepository(
            categoryInfos: categoryInfos, outfitsByPath: outfitsByPath)
        let sut = OutfitPicker(
            config: config,
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: categoryRepository
        )

        let result = try await sut.getAllAvailableOutfitsWithKeys()

        #expect(result.count == 2)
        #expect(result[0].key == "casual/a.avatar")
        #expect(result[1].key == "casual/z.avatar")
    }

    @Test func isWornDelegatesToIsOutfitWorn() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar"],
            cache: cache
        )

        let outfit = makeOutfitReference(
            root: "/Users/test/Outfits", category: "casual", fileName: "shirt.avatar")
        let result = try await env.sut.isWorn(outfit)

        #expect(result == true)
    }

    @Test func getAvailableOutfitsWithCategoryReferenceDelegates() async throws {
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar"]
        )

        let category = CategoryReference(name: "casual", path: "/Users/test/Outfits/casual")
        let result = try await env.sut.getAvailableOutfits(from: category)

        #expect(result.count == 2)
    }

    @Test func getWornOutfitsWithCategoryReferenceDelegates() async throws {
        let cache = OutfitCache(
            categories: [
                "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
            ]
        )
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar", "pants.avatar"],
            cache: cache
        )

        let category = CategoryReference(name: "casual", path: "/Users/test/Outfits/casual")
        let result = try await env.sut.getWornOutfits(from: category)

        #expect(result.count == 1)
        #expect(result[0].fileName == "shirt.avatar")
    }

    @Test func getOutfitStateWithCategoryReferenceDelegates() async throws {
        let env = try makeSingleCategorySUT(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let category = CategoryReference(name: "casual", path: "/Users/test/Outfits/casual")
        let result = try await env.sut.getOutfitState(for: category)

        #expect(result.category.name == "casual")
        #expect(result.totalCount == 1)
    }
}
