import Foundation
import OutfitPickerTestSupport

@testable import OutfitPickerCore

// MARK: - Common Test Environment

struct OutfitPickerTestEnv {
    let sut: OutfitPicker
    let fileManager: FakeFileManager
    let cache: FakeCacheService
    let config: FakeConfigService
}

// MARK: - SUT Creation Helpers

func makeOutfitPickerSUT(
    root: String = "/Users/test/Outfits",
    config: Config? = nil,
    cache: OutfitCache = OutfitCache(),
    fileSystem: [URL: [URL]] = [:],
    directories: [URL] = []
) throws -> OutfitPickerTestEnv {
    let actualConfig = try config ?? Config(root: root, language: "en")
    let configSvc = FakeConfigService(.ok(actualConfig))
    let cacheSvc = FakeCacheService(.ok(cache))
    let fm = FakeFileManager(.ok(fileSystem), directories: directories)

    let sut = OutfitPicker(
        configService: configSvc,
        cacheService: cacheSvc,
        fileManager: fm
    )

    return OutfitPickerTestEnv(
        sut: sut,
        fileManager: fm,
        cache: cacheSvc,
        config: configSvc
    )
}

func makeOutfitPickerSUTWithCategory(
    root: String = "/Users/test/Outfits",
    category: String,
    files: [String],
    cache: OutfitCache = OutfitCache(),
    config: Config? = nil
) throws -> OutfitPickerTestEnv {
    let fs = makeFS(root: root, categories: [category: files])
    let actualConfig = try config ?? Config(root: root, language: "en")

    return try makeOutfitPickerSUT(
        root: root,
        config: actualConfig,
        cache: cache,
        fileSystem: fs.contents,
        directories: Array(fs.directories)
    )
}

// MARK: - Error Testing Helpers

func makeOutfitPickerSUTWithConfigError(_ error: Error) -> OutfitPicker {
    OutfitPicker(
        configService: FakeConfigService(.throwsError(error)),
        cacheService: FakeCacheService(.ok(OutfitCache())),
        fileManager: FakeFileManager(.ok([:]))
    )
}

func makeOutfitPickerSUTWithCacheError(_ error: Error) throws -> OutfitPicker {
    let config = try Config(root: "/Users/test/Outfits", language: "en")
    return OutfitPicker(
        configService: FakeConfigService(.ok(config)),
        cacheService: FakeCacheService(.throwsOnLoad(error)),
        fileManager: FakeFileManager(.ok([:]))
    )
}

func makeOutfitPickerSUTWithFileSystemError(_ error: Error) throws
    -> OutfitPicker
{
    let config = try Config(root: "/Users/test/Outfits", language: "en")
    return OutfitPicker(
        configService: FakeConfigService(.ok(config)),
        cacheService: FakeCacheService(.ok(OutfitCache())),
        fileManager: FakeFileManager(.throwsError(error))
    )
}

// MARK: - Reference Helpers

func makeOutfitReference(root: String, category: String, fileName: String)
    -> OutfitReference
{
    let categoryPath = URL(filePath: root, directoryHint: .isDirectory)
        .appending(path: category, directoryHint: .isDirectory)
        .path(percentEncoded: false)

    let categoryRef = CategoryReference(name: category, path: categoryPath)
    return OutfitReference(fileName: fileName, category: categoryRef)
}
