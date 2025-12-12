import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct CategoryInfoTests {

    private let root = "/Users/test/Outfits"

    @Test
    func mixedStates_excludedEmptyNoAvatarAndHasOutfits_sortedAlphabetically() async throws {
        let sut = OutfitPicker(
            configService: FakeConfigService(
                .ok(
                    try Config(
                        root: root,
                        language: "en",
                        excludedCategories: ["B_Excluded"]
                    )
                )
            ),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: FakeFileManager(
                .ok(
                    makeFS(
                        root: root,
                        categories: [
                            "D_HasOutfits": ["d1.avatar", "d2.avatar"],
                            "A_Empty": [],
                            "C_NoAvatar": ["readme.txt", "photo.png"],
                            "B_Excluded": ["b.avatar"],
                        ]
                    ).contents),
                directories: [
                    URL(filePath: root, directoryHint: .isDirectory),
                    URL(filePath: "\(root)/D_HasOutfits", directoryHint: .isDirectory),
                    URL(filePath: "\(root)/A_Empty", directoryHint: .isDirectory),
                    URL(filePath: "\(root)/C_NoAvatar", directoryHint: .isDirectory),
                    URL(filePath: "\(root)/B_Excluded", directoryHint: .isDirectory),
                ]
            )
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
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let fm = FakeFileManager(.ok([rootURL: []]), directories: [])
        let sut = OutfitPicker(
            configService: FakeConfigService(
                .ok(try Config(root: root, language: "en"))
            ),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: fm
        )

        let infos = try await sut.getCategoryInfo()

        #expect(infos.isEmpty)
    }

    @Test
    func failure_configLoad_mapsToInvalidConfiguration() async {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: FakeFileManager(.ok([:]))
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
        let fm = FakeFileManager(
            .throwsError(FileSystemError.operationFailed)
        )
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: fm
        )

        do {
            _ = try await sut.getCategoryInfo()
            Issue.record("Expected fileSystemError when root listing fails.")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
