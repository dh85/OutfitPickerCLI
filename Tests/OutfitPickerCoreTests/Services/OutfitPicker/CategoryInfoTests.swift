import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct CategoryInfoTests {

    private let root = "/Users/test/Outfits"

    @Test
    func mixedStates_excludedEmptyNoAvatarAndHasOutfits_sortedAlphabetically() async throws {
        let categoryInfos = [
            CategoryInfo(
                category: CategoryReference(name: "A_Empty", path: "\(root)/A_Empty"),
                state: .empty, outfitCount: 0),
            CategoryInfo(
                category: CategoryReference(name: "B_Excluded", path: "\(root)/B_Excluded"),
                state: .userExcluded, outfitCount: 0),
            CategoryInfo(
                category: CategoryReference(name: "C_NoAvatar", path: "\(root)/C_NoAvatar"),
                state: .noAvatarFiles, outfitCount: 0),
            CategoryInfo(
                category: CategoryReference(name: "D_HasOutfits", path: "\(root)/D_HasOutfits"),
                state: .hasOutfits, outfitCount: 2),
        ]
        let categoryRepository = FakeCategoryRepository(categoryInfos: categoryInfos)
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: ["B_Excluded"]
        )
        let sut = OutfitPicker(
            config: config,
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: categoryRepository
        )

        let infos = try await sut.getCategoryInfo()

        // We should have *four* categories (non-directory "loose.txt" is skipped)
        #expect(infos.count == 4)

        // Alphabetical order: A, B, C, D
        #expect(infos[0].category.name == "A_Empty")
        #expect(infos[0].state == .empty)
        #expect(infos[0].outfitCount == 0)

        #expect(infos[1].category.name == "B_Excluded")
        #expect(infos[1].state == .userExcluded)
        #expect(infos[1].outfitCount == 0)

        #expect(infos[2].category.name == "C_NoAvatar")
        #expect(infos[2].state == .noAvatarFiles)
        #expect(infos[2].outfitCount == 0)

        #expect(infos[3].category.name == "D_HasOutfits")
        #expect(infos[3].state == .hasOutfits)
        #expect(infos[3].outfitCount == 2)
    }

    @Test
    func noChildrenAtRoot_returnsEmptyArray() async throws {
        let categoryRepository = FakeCategoryRepository(categoryInfos: [])
        let config = try Config(root: root, language: "en")
        let sut = OutfitPicker(
            config: config,
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: categoryRepository
        )

        let infos = try await sut.getCategoryInfo()

        #expect(infos.isEmpty)
    }

    @Test
    func failure_configLoad_mapsToInvalidConfiguration() async {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let dummyConfig = try! Config(root: "/Users/test/outfits", language: "en")
        let sut = OutfitPicker(
            config: dummyConfig,
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: FakeCategoryRepository()
        )

        do {
            _ = try await sut.getCategoryInfo()
            Issue.record("Expected invalidConfiguration when config load fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test
    func failure_rootListing_mapsToFileSystemError() async throws {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        _ = FakeFileManager(
            .throwsError(FileSystemError.operationFailed)
        )
        let categoryRepository = ThrowingCategoryRepository(FileSystemError.operationFailed)
        let sut = OutfitPicker(
            config: config,
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            repository: categoryRepository
        )

        do {
            _ = try await sut.getCategoryInfo()
            Issue.record("Expected fileSystemError when root listing fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
