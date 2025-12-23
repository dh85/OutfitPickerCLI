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

    // Convert fileSystem to CategoryScanner data
    let categoryInfos = directories.compactMap { url -> CategoryInfo? in
        guard url.path(percentEncoded: false).hasPrefix(root),
            url.path(percentEncoded: false) != root
        else { return nil }
        let categoryName = url.lastPathComponent
        let files = fileSystem[url] ?? []
        let avatarFiles = files.filter { $0.pathExtension.lowercased() == "avatar" }
        let allFiles = files.filter { !$0.hasDirectoryPath }

        let state: CategoryState
        if actualConfig.excludedCategories.contains(categoryName) {
            state = .userExcluded
        } else if avatarFiles.isEmpty {
            state = allFiles.isEmpty ? .empty : .noAvatarFiles
        } else {
            state = .hasOutfits
        }

        return CategoryInfo(
            category: CategoryReference(name: categoryName, path: url.path(percentEncoded: false)),
            state: state,
            outfitCount: avatarFiles.count
        )
    }

    let outfitsByPath = directories.reduce(into: [String: [FileEntry]]()) { result, url in
        let files = fileSystem[url] ?? []
        let avatarFiles = files.filter { $0.pathExtension.lowercased() == "avatar" }
        result[url.path(percentEncoded: false)] = avatarFiles.map {
            FileEntry(filePath: $0.path(percentEncoded: false))
        }
    }

    let categoryRepository = FakeCategoryRepository(
        categoryInfos: categoryInfos, outfitsByPath: outfitsByPath)
    let sut = OutfitPicker(
        config: actualConfig,
        configService: configSvc,
        cacheService: cacheSvc,
        repository: categoryRepository
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
    let actualConfig = try config ?? Config(root: root, language: "en")
    // Use URL path building to match OutfitPicker.buildCategoryPath
    let categoryPath = URL(filePath: root, directoryHint: .isDirectory)
        .appending(path: category, directoryHint: .isDirectory)
        .path(percentEncoded: false)

    let categoryRepository = FakeCategoryRepository(
        categoryInfos: [
            CategoryInfo(
                category: CategoryReference(name: category, path: categoryPath),
                state: files.isEmpty ? .empty : .hasOutfits,
                outfitCount: files.count
            )
        ],
        outfitsByPath: [categoryPath: files.map { FileEntry(filePath: "\(categoryPath)/\($0)") }]
    )

    let configSvc = FakeConfigService(.ok(actualConfig))
    let cacheSvc = FakeCacheService(.ok(cache))
    let fm = FakeFileManager(.ok([:]), directories: [])

    let sut = OutfitPicker(
        config: actualConfig,
        configService: configSvc,
        cacheService: cacheSvc,
        repository: categoryRepository
    )

    return OutfitPickerTestEnv(
        sut: sut,
        fileManager: fm,
        cache: cacheSvc,
        config: configSvc
    )
}

// MARK: - Error Testing Helpers

func makeOutfitPickerSUTWithConfigError(_ error: Error) -> OutfitPicker {
    let dummyConfig = try! Config(root: "/Users/test/Outfits")
    return OutfitPicker(
        config: dummyConfig,
        configService: FakeConfigService(.throwsError(error)),
        cacheService: FakeCacheService(.ok(OutfitCache())),
        repository: FakeCategoryRepository()
    )
}

func makeOutfitPickerSUTWithCacheError(_ error: Error) throws -> OutfitPicker {
    let config = try Config(root: "/Users/test/Outfits", language: "en")
    return OutfitPicker(
        config: config,
        configService: FakeConfigService(.ok(config)),
        cacheService: FakeCacheService(.throwsOnLoad(error)),
        repository: FakeCategoryRepository()
    )
}

func makeOutfitPickerSUTWithCategoryScannerError(_ error: Error) throws
    -> OutfitPicker
{
    let config = try Config(root: "/Users/test/Outfits", language: "en")
    let categoryRepository = ThrowingCategoryRepository(error)
    return OutfitPicker(
        config: config,
        configService: FakeConfigService(.ok(config)),
        cacheService: FakeCacheService(.ok(OutfitCache())),
        repository: categoryRepository
    )
}

// MARK: - Single Category Helpers

func makeSingleCategorySUT(
    root: String = "/Users/test/Outfits",
    category: String,
    files: [String],
    cache: OutfitCache = OutfitCache(),
    config: Config? = nil
) throws -> OutfitPickerTestEnv {
    return try makeOutfitPickerSUTWithCategory(
        root: root,
        category: category,
        files: files,
        cache: cache,
        config: config
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

// MARK: - Path Normalization

func normPath(_ path: String) -> String {
    return path.hasSuffix("/") ? String(path.dropLast()) : path
}
