import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

// MARK: - Change detection & updateConfig tests

struct ChangeDetectionTests {

    // MARK: - detectChanges

    @Test(
        "detectChanges uses knownCategories when knownCategoryFiles is empty and reports new + changed categories and added files"
    )
    func detectChanges_usesKnownCategoriesFallback() async throws {
        let root = "/Users/test/Outfits"
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["A", "B"],
            knownCategoryFiles: [:]
        )
        let fs = makeFS(
            root: root,
            categories: [
                "A": ["a1.avatar"],
                "B": ["b1.avatar"],
                "C": ["c1.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            config: config,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let changes = try await env.sut.detectChanges()

        #expect(changes.newCategories == Set(["C"]))
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories == Set(["A", "B"]))
        #expect(changes.addedFiles["A"] == Set(["a1.avatar"]))
        #expect(changes.addedFiles["B"] == Set(["b1.avatar"]))
        #expect(changes.deletedFiles.isEmpty)
    }

    @Test(
        "detectChanges uses knownCategoryFiles when present and reports added/deleted files per category"
    )
    func detectChanges_usesKnownCategoryFiles() async throws {
        let root = "/Users/test/Outfits"
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: [],
            knownCategoryFiles: [
                "A": ["old1.avatar", "old2.avatar"],
                "B": ["b1.avatar"],
            ]
        )
        let fs = makeFS(
            root: root,
            categories: [
                "A": ["old2.avatar", "newA.avatar"],
                "B": [],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            config: config,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let changes = try await env.sut.detectChanges()

        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories == Set(["A", "B"]))
        #expect(changes.addedFiles["A"] == Set(["newA.avatar"]))
        #expect(changes.deletedFiles["A"] == Set(["old1.avatar"]))
        #expect(
            changes.addedFiles["B"] == nil || changes.addedFiles["B"]!.isEmpty
        )
        #expect(changes.deletedFiles["B"] == Set(["b1.avatar"]))
    }

    @Test(
        "detectChanges returns empty changes when FS matches knownCategoryFiles"
    )
    func detectChanges_noChanges() async throws {
        let root = "/Users/test/Outfits"
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: [],
            knownCategoryFiles: ["Solo": ["x.avatar"]]
        )
        let fs = makeFS(root: root, categories: ["Solo": ["x.avatar"]])

        let env = try makeOutfitPickerSUT(
            root: root,
            config: config,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let changes = try await env.sut.detectChanges()

        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories.isEmpty)
        #expect(changes.addedFiles.isEmpty)
        #expect(changes.deletedFiles.isEmpty)
        #expect(changes.isEmpty)
    }

    @Test("detectChanges maps ConfigError via OutfitPickerError.from")
    func detectChanges_mapsConfigError() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        do {
            _ = try await sut.detectChanges()
            Issue.record("Expected invalidConfiguration")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    // MARK: - updateConfig

    @Test(
        "updateConfig updates config based on current FS and does not reset cache when deletedCategories is empty"
    )
    func updateConfig_updatesConfigWithoutCacheReset() async throws {
        let root = "/Users/test/Outfits"
        let original = try Config(
            root: root,
            language: "en",
            excludedCategories: ["Excluded"],
            knownCategories: ["Old"],
            knownCategoryFiles: ["Old": ["old1.avatar"]]
        )
        let fs = makeFS(
            root: root,
            categories: ["NewCat": ["one.avatar", "two.avatar"]]
        )
        let cache = OutfitCache(categories: [
            "NewCat": .init(wornOutfits: ["one.avatar"], totalOutfits: 2)
        ])

        let configSvc = CapturingConfigService(initial: original)
        let cacheSvc = FakeCacheService(.ok(cache))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = CategoryChanges(
            newCategories: ["NewCat"],
            deletedCategories: [],
            changedCategories: [],
            addedFiles: [:],
            deletedFiles: [:]
        )

        try await sut.updateConfig(with: changes)

        #expect(configSvc.saved.count == 1)
        let saved = try #require(configSvc.saved.first)

        #expect(saved.root == original.root)
        #expect(saved.language == original.language)
        #expect(saved.excludedCategories == original.excludedCategories)
        #expect(saved.knownCategories == Set(["NewCat"]))
        #expect(
            saved.knownCategoryFiles["NewCat"]
                == Set(["one.avatar", "two.avatar"])
        )
        #expect(cacheSvc.saved.isEmpty)
    }

    @Test("updateConfig resets cache when deletedCategories is non-empty")
    func updateConfig_resetsCacheWhenDeletedCategoriesPresent() async throws {
        let root = "/Users/test/Outfits"
        let original = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["Old"],
            knownCategoryFiles: ["Old": ["old1.avatar"]]
        )
        let fs = makeFS(root: root, categories: ["Cat": ["one.avatar"]])
        let initialCache = OutfitCache(categories: [
            "Cat": .init(wornOutfits: ["one.avatar"], totalOutfits: 3)
        ])

        let configSvc = CapturingConfigService(initial: original)
        let cacheSvc = FakeCacheService(.ok(initialCache))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = CategoryChanges(
            newCategories: [],
            deletedCategories: ["OldCategory"],
            changedCategories: [],
            addedFiles: [:],
            deletedFiles: [:]
        )

        try await sut.updateConfig(with: changes)

        #expect(configSvc.saved.count == 1)
        #expect(cacheSvc.saved.count == 1)

        let resetCache = try #require(cacheSvc.saved.first)
        #expect(resetCache.version == initialCache.version)
        #expect(resetCache.createdAt == initialCache.createdAt)
        #expect(
            Set(resetCache.categories.keys) == Set(initialCache.categories.keys)
        )

        for (name, before) in initialCache.categories {
            let after = try #require(resetCache.categories[name])
            #expect(after.totalOutfits == before.totalOutfits)
            #expect(after.wornOutfits.isEmpty)
        }
    }

    @Test(
        "detectChanges hits `currentFiles == nil` case and records deleted files"
    )
    func detectChanges_nilCurrentFilesCase() async throws {
        let root = "/Users/test/Outfits"
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["X"],
            knownCategoryFiles: ["X": ["old.avatar"]]
        )

        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let xDir = rootURL.appending(path: "X", directoryHint: .isDirectory)

        let env = try makeOutfitPickerSUT(
            root: root,
            config: config,
            fileSystem: [rootURL: [xDir]],  // no mapping for xDir itself
            directories: [rootURL, xDir]
        )

        let changes = try await env.sut.detectChanges()

        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories == ["X"])
        #expect(changes.deletedFiles["X"] == ["old.avatar"])
        #expect(changes.addedFiles["X"] == nil)
    }

    @Test(
        "updateConfig maps ConfigError from load using OutfitPickerError.from"
    )
    func updateConfig_mapsConfigError() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)
        let changes = CategoryChanges()

        do {
            try await sut.updateConfig(with: changes)
            Issue.record("Expected invalidConfiguration")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}

// MARK: - Extra test doubles (compatible with your existing ones)

/// A ConfigService that returns a fixed initial config and records every save.
final class CapturingConfigService: ConfigServiceProtocol, @unchecked Sendable {
    private let initial: Config
    private(set) var saved: [Config] = []

    init(initial: Config) {
        self.initial = initial
    }

    func load() throws -> Config { initial }

    func save(_ config: Config) throws {
        saved.append(config)
    }

    func delete() throws { fatalError("not used in these tests") }

    func configPath() throws -> URL {
        URL(filePath: "/dev/null", directoryHint: .notDirectory)
    }
}

/// A ConfigService that always throws a given error (for error-mapping paths).
final class ThrowingConfigService: ConfigServiceProtocol, @unchecked Sendable {
    let error: Error
    init(error: Error) { self.error = error }

    func load() throws -> Config { throw error }
    func save(_ config: Config) throws { throw error }
    func delete() throws { throw error }
    func configPath() throws -> URL {
        URL(filePath: "/dev/null", directoryHint: .notDirectory)
    }
}
