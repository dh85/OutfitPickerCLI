import Foundation
import OutfitPickerCore

/// Test fixtures and SUT containers for OutfitPicker testing.
///
/// This module provides pre-configured System Under Test (SUT) containers
/// that simplify test setup for common testing scenarios.

// MARK: - System Under Test Containers

/// Container for single-category testing scenarios.
///
/// Provides a configured OutfitPicker instance with fake dependencies
/// for testing single category operations.
public struct SingleCategorySUT {
    /// The OutfitPicker instance under test
    public let sut: OutfitPicker
    /// Fake file manager for controlling filesystem behavior
    public let fileManager: FakeFileManager
    /// Fake cache service for controlling cache behavior
    public let cache: FakeCacheService
    /// Fake config service for controlling configuration
    public let config: FakeConfigService
}

/// Creates a configured system under test for single category scenarios.
///
/// - Parameters:
///   - root: Root directory path (defaults to "/Users/test/Outfits")
///   - category: The category name to create
///   - files: Array of file names in the category
///   - cache: Initial cache state (defaults to empty cache)
/// - Returns: Configured SingleCategorySUT instance
/// - Throws: Configuration errors if invalid parameters provided
///
/// ## Usage Example
/// ```swift
/// let sut = try makeSingleCategorySUT(
///     category: "casual",
///     files: ["shirt1.avatar", "pants1.avatar"]
/// )
/// let result = sut.sut.showRandomOutfit(from: "casual")
/// ```
@discardableResult
public func makeSingleCategorySUT(
    root: String = "/Users/test/Outfits",
    category: String,
    files: [String],
    cache: OutfitCache = OutfitCache()
) throws -> SingleCategorySUT {
    let config = try Config(root: root, language: "en")
    let configSvc = FakeConfigService(.ok(config))
    let (_, map) = makeCategoryDir(root: root, name: category, files: files)
    let fm = FakeFileManager(
        .ok(map),
        directories: [URL(filePath: root, directoryHint: .isDirectory)]
    )
    let cacheSvc = FakeCacheService(.ok(cache))

    let categoryRepository = FakeCategoryRepository(
        categoryInfos: [
            CategoryInfo(
                category: CategoryReference(name: category, path: "\(root)/\(category)"),
                state: .hasOutfits,
                outfitCount: files.count
            )
        ],
        outfitsByPath: [
            "\(root)/\(category)": files.map { FileEntry(filePath: "\(root)/\(category)/\($0)") }
        ]
    )

    let sut = OutfitPicker(
        config: config,
        configService: configSvc,
        cacheService: cacheSvc,
        repository: categoryRepository
    )
    return .init(sut: sut, fileManager: fm, cache: cacheSvc, config: configSvc)
}

/// Container for multi-category testing scenarios.
///
/// Provides a configured OutfitPicker instance with fake dependencies
/// for testing operations across multiple categories.
public struct AcrossCategoriesSUT {
    /// The OutfitPicker instance under test
    public let sut: OutfitPicker
    /// Fake file manager for controlling filesystem behavior
    public let fileManager: FakeFileManager
    /// Fake cache service for controlling cache behavior
    public let cache: FakeCacheService
    /// Fake config service for controlling configuration
    public let config: FakeConfigService
}

/// Creates a configured system under test for multi-category scenarios.
///
/// - Parameters:
///   - root: Root directory path (defaults to "/Users/test/Outfits")
///   - categories: Dictionary mapping category names to their file lists
///   - excluded: Set of category names to exclude (defaults to empty)
///   - cache: Initial cache state (defaults to empty cache)
/// - Returns: Configured AcrossCategoriesSUT instance
/// - Throws: Configuration errors if invalid parameters provided
///
/// ## Usage Example
/// ```swift
/// let sut = try makeAcrossCategoriesSUT(
///     categories: [
///         "casual": ["shirt1.avatar"],
///         "formal": ["suit1.avatar"]
///     ],
///     excluded: ["old"]
/// )
/// let result = sut.sut.showRandomOutfitAcrossCategories()
/// ```
@discardableResult
public func makeAcrossCategoriesSUT(
    root: String = "/Users/test/Outfits",
    categories: [String: [String]],
    excluded: Set<String> = [],
    cache: OutfitCache = OutfitCache()
) throws -> AcrossCategoriesSUT {
    let config = try Config(
        root: root,
        language: "en",
        excludedCategories: excluded
    )
    let configSvc = FakeConfigService(.ok(config))

    let fs = makeFS(root: root, categories: categories)
    let fm = FakeFileManager(
        .ok(fs.contents),
        directories: Array(fs.directories)
    )
    let cacheSvc = FakeCacheService(.ok(cache))

    let categoryInfos = categories.map { name, files in
        CategoryInfo(
            category: CategoryReference(name: name, path: "\(root)/\(name)"),
            state: .hasOutfits,
            outfitCount: files.count
        )
    }

    let outfitsByPath = categories.reduce(into: [String: [FileEntry]]()) { result, pair in
        let (name, files) = pair
        let path = "\(root)/\(name)"
        result[path] = files.map { FileEntry(filePath: "\(path)/\($0)") }
    }

    let categoryRepository = FakeCategoryRepository(
        categoryInfos: categoryInfos,
        outfitsByPath: outfitsByPath
    )

    let sut = OutfitPicker(
        config: config,
        configService: configSvc,
        cacheService: cacheSvc,
        repository: categoryRepository
    )
    return .init(sut: sut, fileManager: fm, cache: cacheSvc, config: configSvc)
}
