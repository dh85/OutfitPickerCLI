import Foundation

/// Manages outfit selection and rotation across categories.
///
/// OutfitPicker provides intelligent outfit selection with automatic rotation tracking,
/// ensuring you don't repeat outfits until all have been worn. Perfect for daily outfit
/// selection, wardrobe management, and style rotation.
///
/// ## Quick Start
/// ```swift
/// // Simple initialization - no configuration needed
/// let picker = OutfitPicker()
///
/// // Setup your outfit directory
/// let config = try Config(root: "/Users/me/Outfits")
/// let configService = ConfigService()
/// try configService.save(config)
///
/// // Get a random outfit from "casual" category
/// if let outfit = try await picker.showRandomOutfit(from: "casual") {
///     print("Wear: \(outfit.fileName)")
///     try await picker.wearOutfit(outfit)
/// }
/// ```
///
/// ## Type-Safe API
/// Use CategoryReference for compile-time safety:
/// ```swift
/// let categories = try await picker.getCategories()
/// if let casual = categories.first(where: { $0.name == "casual" }) {
///     let outfit = try await picker.showRandomOutfit(from: casual)
///     let available = try await picker.getAvailableCount(for: casual)
/// }
/// ```
public protocol OutfitPickerProtocol: Sendable {
    /// Selects a random unworn outfit from the specified category.
    ///
    /// Automatically tracks worn outfits and resets rotation when all outfits
    /// in the category have been worn. Returns `nil` if category is empty.
    ///
    /// - Parameter categoryName: Name of the category to select from
    /// - Returns: Random unworn outfit, or `nil` if category has no outfits
    /// - Throws: `OutfitPickerError.invalidInput` if category name is empty
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// if let outfit = try await picker.showRandomOutfit(from: "work") {
    ///     print("Today's work outfit: \(outfit.fileName)")
    /// }
    /// ```
    func showRandomOutfit(from categoryName: String) async throws
        -> OutfitReference?

    /// Selects a random unworn outfit from any available category.
    ///
    /// Useful for spontaneous outfit selection when you want variety across
    /// your entire wardrobe. Excludes user-excluded categories.
    ///
    /// - Returns: Random unworn outfit from any category, or `nil` if no outfits available
    /// - Throws: `OutfitPickerError.noOutfitsAvailable` if no categories have outfits
    ///
    /// ## Example
    /// ```swift
    /// if let outfit = try await picker.showRandomOutfitAcrossCategories() {
    ///     print("Surprise outfit from \(outfit.category.name): \(outfit.fileName)")
    /// }
    /// ```
    func showRandomOutfitAcrossCategories() async throws -> OutfitReference?

    /// Shows all outfits that have been worn at least once, grouped by category.
    ///
    /// Use this to inspect which outfits you've already worn, for example to
    /// review your history or debug rotation logic. Categories with no worn
    /// outfits are omitted from the result.
    ///
    /// The returned dictionary uses the category name as the key and an array of
    /// outfit file names as the value.
    ///
    /// - Returns: A dictionary of category names mapped to arrays of worn outfit
    ///   file names. Categories with no worn outfits are not included.
    /// - Throws: `OutfitPickerError` if the cache cannot be loaded or decoded.
    ///
    /// ## Example
    /// ```swift
    /// let wornByCategory = try await picker.showAllWornOutfits()
    ///
    /// for (category, outfits) in wornByCategory {
    ///     print("Worn in \(category):")
    ///     for fileName in outfits {
    ///         print("  • \(fileName)")
    ///     }
    /// }
    /// ```
    func showAllWornOutfits() async throws -> [String: [String]]

    /// Shows all outfits that have not been worn yet, grouped by category.
    ///
    /// Useful for discovering unworn outfits across your wardrobe or for building
    /// "only-new" rotations. Categories in which every outfit has been worn are
    /// omitted from the result.
    ///
    /// The returned dictionary uses the category name as the key and an array of
    /// unworn outfit file names as the value.
    ///
    /// - Returns: A dictionary of category names mapped to arrays of unworn outfit
    ///   file names. Categories where all outfits have been worn are not included.
    /// - Throws: `OutfitPickerError` if the cache cannot be loaded or decoded, or
    ///   file-system errors if avatar directories cannot be read.
    ///
    /// ## Example
    /// ```swift
    /// let unwornByCategory = try await picker.showAllUnwornOutfit()
    ///
    /// for (category, outfits) in unwornByCategory {
    ///     print("Still unworn in \(category):")
    ///     for fileName in outfits {
    ///         print("  • \(fileName)")
    ///     }
    /// }
    /// ```
    ///
    func showAllUnwornOutfits() async throws -> [String: [String]]

    /// Marks an outfit as worn, adding it to the rotation tracking.
    ///
    /// Call this after wearing an outfit to ensure it won't be selected again
    /// until the category rotation completes. Safe to call multiple times.
    ///
    /// - Parameter outfit: The outfit that was worn
    /// - Throws: `OutfitPickerError.invalidInput` if outfit data is invalid
    /// - Throws: `OutfitPickerError.noOutfitsAvailable` if outfit doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// let outfit = try await picker.showRandomOutfit(from: "casual")
    /// // ... wear the outfit ...
    /// try await picker.wearOutfit(outfit)
    /// ```
    func wearOutfit(_ outfit: OutfitReference) async throws

    /// Retrieves detailed information about all categories and their states.
    ///
    /// Provides comprehensive category analysis including outfit counts,
    /// availability status, and exclusion reasons. Useful for UI displays
    /// and wardrobe management.
    ///
    /// - Returns: Array of category information sorted by name
    /// - Throws: `OutfitPickerError.fileSystemError` if filesystem access fails
    ///
    /// ## Example
    /// ```swift
    /// let categories = try await picker.getCategoryInfo()
    /// for info in categories {
    ///     print("\(info.category.name): \(info.state)")
    /// }
    /// ```
    func getCategoryInfo() async throws -> [CategoryInfo]

    /// Retrieves references to all categories that have outfits.
    ///
    /// Returns only categories with available outfits, excluding empty
    /// or user-excluded categories. Perfect for populating selection lists.
    ///
    /// - Returns: Array of category references sorted by name
    /// - Throws: `OutfitPickerError.fileSystemError` if filesystem access fails
    ///
    /// ## Example
    /// ```swift
    /// let categories = try await picker.getCategories()
    /// let categoryNames = categories.map { $0.name }
    /// print("Available categories: \(categoryNames.joined(separator: ", "))")
    /// ```
    func getCategories() async throws -> [CategoryReference]

    /// Returns the count of unworn outfits in a category.
    ///
    /// Useful for displaying progress or determining if new outfits are needed.
    /// Returns total count if rotation just completed.
    ///
    /// - Parameter categoryName: Name of the category to check
    /// - Returns: Number of available (unworn) outfits
    /// - Throws: `OutfitPickerError.invalidInput` if category name is empty
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// let available = try await picker.getAvailableCount(for: "formal")
    /// print("\(available) formal outfits remaining")
    /// ```
    func getAvailableCount(for categoryName: String) async throws -> Int

    /// Resets the worn outfit tracking for a specific category.
    ///
    /// Clears the worn list, making all outfits in the category available
    /// for selection again. Useful for starting fresh or manual resets.
    ///
    /// - Parameter categoryName: Name of the category to reset
    /// - Throws: `OutfitPickerError.invalidInput` if category name is empty
    ///
    /// ## Example
    /// ```swift
    /// try await picker.resetCategory("summer")
    /// print("Summer outfits reset - all available again")
    /// ```
    func resetCategory(_ categoryName: String) async throws

    /// Resets worn outfit tracking for all categories.
    ///
    /// Clears all rotation history, making every outfit available for
    /// selection. Use when starting a new season or major wardrobe refresh.
    ///
    /// - Throws: `OutfitPickerError.cacheError` if reset fails
    ///
    /// ## Example
    /// ```swift
    /// try await picker.resetAllCategories()
    /// print("All outfit rotations reset")
    /// ```
    func resetAllCategories() async throws

    /// Partially resets a category to have only the specified number of worn outfits.
    ///
    /// Useful for fine-tuning rotation state or recovering from tracking issues.
    /// Keeps the first N worn outfits and makes the rest available.
    ///
    /// - Parameters:
    ///   - categoryName: Name of the category to partially reset
    ///   - wornCount: Number of outfits to keep as worn (rest become available)
    /// - Throws: `OutfitPickerError.invalidInput` if parameters are invalid
    ///
    /// ## Example
    /// ```swift
    /// // Keep only 3 outfits as worn, make rest available
    /// try await picker.partialReset(categoryName: "work", wornCount: 3)
    /// ```
    func partialReset(categoryName: String, wornCount: Int) async throws

    /// Retrieves all outfit references from a specific category.
    ///
    /// Returns complete outfit inventory for a category, regardless of
    /// worn status. Useful for wardrobe audits and management interfaces.
    ///
    /// - Parameter categoryName: Name of the category to list
    /// - Returns: Array of all outfits in the category, sorted by filename
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// let outfits = try await picker.showAllOutfits(from: "casual")
    /// print("Casual wardrobe (\(outfits.count) items):")
    /// outfits.forEach { print("- \($0.fileName)") }
    /// ```
    func showAllOutfits(from categoryName: String) async throws
        -> [OutfitReference]

    /// Detects changes in the filesystem compared to stored configuration.
    ///
    /// Scans for new categories, deleted categories, and file changes.
    /// Use before `updateConfig` to synchronize with filesystem state.
    ///
    /// - Returns: Summary of detected changes
    /// - Throws: `OutfitPickerError.fileSystemError` if filesystem scan fails
    ///
    /// ## Example
    /// ```swift
    /// let changes = try await picker.detectChanges()
    /// if !changes.newCategories.isEmpty {
    ///     print("New categories found: \(changes.newCategories.joined(separator: ", "))")
    /// }
    /// ```
    func detectChanges() async throws -> CategoryChanges

    /// Updates the configuration with detected filesystem changes.
    ///
    /// Synchronizes the stored configuration with current filesystem state.
    /// Automatically clears cache for deleted categories.
    ///
    /// - Parameter changes: Changes to apply (from `detectChanges`)
    /// - Throws: `OutfitPickerError.invalidConfiguration` if update fails
    ///
    /// ## Example
    /// ```swift
    /// let changes = try await picker.detectChanges()
    /// try await picker.updateConfig(with: changes)
    /// print("Configuration synchronized")
    /// ```
    func updateConfig(with changes: CategoryChanges) async throws

    /// Marks multiple outfits as worn in a single efficient operation.
    ///
    /// Batch operation for marking several outfits as worn. More efficient
    /// than calling `wearOutfit` multiple times. All outfits must exist.
    ///
    /// - Parameter outfits: Array of outfits to mark as worn
    /// - Throws: `OutfitPickerError.invalidInput` if any outfit data is invalid
    /// - Throws: `OutfitPickerError.noOutfitsAvailable` if any outfit doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// let outfitsWorn = [outfit1, outfit2, outfit3]
    /// try await picker.wearOutfits(outfitsWorn)
    /// print("Marked \(outfitsWorn.count) outfits as worn")
    /// ```
    func wearOutfits(_ outfits: [OutfitReference]) async throws

    /// Resets multiple categories in a single efficient operation.
    ///
    /// Batch operation for resetting several categories. More efficient
    /// than calling `resetCategory` multiple times.
    ///
    /// - Parameter categoryNames: Array of category names to reset
    /// - Throws: `OutfitPickerError.invalidInput` if any category name is invalid
    ///
    /// ## Example
    /// ```swift
    /// try await picker.resetCategories(["summer", "vacation", "beach"])
    /// print("Summer categories reset")
    /// ```
    func resetCategories(_ categoryNames: [String]) async throws

    /// Searches for outfits matching the given pattern.
    ///
    /// Performs case-insensitive search across all outfit filenames in
    /// available categories. Excludes user-excluded categories.
    ///
    /// - Parameter pattern: Search pattern to match against outfit names
    /// - Returns: Array of matching outfits, sorted by filename
    /// - Throws: `OutfitPickerError.invalidInput` if pattern is empty
    ///
    /// ## Example
    /// ```swift
    /// let blueOutfits = try await picker.searchOutfits(pattern: "blue")
    /// print("Found \(blueOutfits.count) blue outfits")
    /// ```
    func searchOutfits(pattern: String) async throws -> [OutfitReference]

    /// Filters categories by name pattern.
    ///
    /// Performs case-insensitive search across category names.
    /// Only returns categories that have outfits.
    ///
    /// - Parameter pattern: Pattern to match against category names
    /// - Returns: Array of matching categories, sorted by name
    /// - Throws: `OutfitPickerError.invalidInput` if pattern is empty
    ///
    /// ## Example
    /// ```swift
    /// let workCategories = try await picker.filterCategories(pattern: "work")
    /// print("Work-related categories: \(workCategories.map { $0.name })")
    /// ```
    func filterCategories(pattern: String) async throws -> [CategoryReference]

    // MARK: - Convenience Methods

    /// Checks if a specific outfit exists in a category.
    ///
    /// Useful for validating outfit references before operations.
    ///
    /// - Parameters:
    ///   - fileName: Name of the outfit file to check
    ///   - categoryName: Name of the category to search in
    /// - Returns: `true` if the outfit exists, `false` otherwise
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    func outfitExists(_ fileName: String, in categoryName: String) async throws
        -> Bool

    /// Checks if a specific outfit has been worn in the current rotation.
    ///
    /// Returns `false` for outfits that don't exist or haven't been worn.
    ///
    /// - Parameters:
    ///   - fileName: Name of the outfit file to check
    ///   - categoryName: Name of the category containing the outfit
    /// - Returns: `true` if the outfit has been worn, `false` otherwise
    func isOutfitWorn(_ fileName: String, in categoryName: String) async throws
        -> Bool

    /// Gets a specific outfit reference by name.
    ///
    /// Useful for converting filename strings to OutfitReference objects.
    ///
    /// - Parameters:
    ///   - fileName: Name of the outfit file to retrieve
    ///   - categoryName: Name of the category containing the outfit
    /// - Returns: OutfitReference if found, `nil` if outfit doesn't exist
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    func getOutfit(_ fileName: String, from categoryName: String) async throws
        -> OutfitReference?

    /// Gets the rotation progress for a category as (worn, total) counts.
    ///
    /// Returns the exact number of worn outfits and total outfits in the category.
    /// Useful for displaying detailed progress information.
    ///
    /// - Parameter categoryName: Name of the category to check
    /// - Returns: Tuple with worn count and total count
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    func getRotationProgress(for categoryName: String) async throws -> (
        worn: Int, total: Int
    )

    /// Gets the rotation progress for a category as a percentage (0.0 to 1.0).
    ///
    /// Returns 1.0 for empty categories. Useful for progress bars and indicators.
    ///
    /// - Parameter categoryName: Name of the category to check
    /// - Returns: Progress as a decimal between 0.0 and 1.0
    /// - Throws: `OutfitPickerError.categoryNotFound` if category doesn't exist
    func getRotationProgressPercentage(for categoryName: String) async throws
        -> Double

    // MARK: - Type-Safe CategoryReference Overloads

    /// Type-safe version of showRandomOutfit(from:) using CategoryReference.
    ///
    /// Eliminates typos and provides compile-time safety for category names.
    func showRandomOutfit(from category: CategoryReference) async throws
        -> OutfitReference?

    /// Type-safe version of getAvailableCount(for:) using CategoryReference.
    func getAvailableCount(for category: CategoryReference) async throws -> Int

    /// Type-safe version of resetCategory(_:) using CategoryReference.
    func resetCategory(_ category: CategoryReference) async throws

    /// Type-safe version of partialReset(categoryName:wornCount:) using CategoryReference.
    func partialReset(category: CategoryReference, wornCount: Int) async throws

    /// Type-safe version of showAllOutfits(from:) using CategoryReference.
    func showAllOutfits(from category: CategoryReference) async throws
        -> [OutfitReference]

    /// Type-safe version of getRotationProgress(for:) using CategoryReference.
    func getRotationProgress(for category: CategoryReference) async throws -> (
        worn: Int, total: Int
    )
}

/// Protocol abstracting FileManager operations for testability.
public protocol FileManagerProtocol {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL]

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws

    func removeItem(at URL: URL) throws
}

extension FileManager: FileManagerProtocol {}

/// Main implementation of the outfit picker functionality.
///
/// OutfitPicker manages outfit selection with intelligent rotation tracking.
/// It automatically prevents outfit repetition until all outfits in a category
/// have been worn, then resets for a fresh rotation cycle.
///
/// ## Thread Safety
/// OutfitPicker is thread-safe and can be used from multiple concurrent contexts.
/// All operations are atomic and properly synchronized.
///
/// ## Error Handling
/// All methods throw `OutfitPickerError` for consistent error handling:
/// - `configurationNotFound`: No configuration file exists
/// - `categoryNotFound`: Requested category doesn't exist
/// - `noOutfitsAvailable`: No outfit files found
/// - `invalidInput`: Invalid parameters provided
/// - `fileSystemError`: Filesystem access issues
/// - `cacheError`: Cache corruption or access issues
public actor OutfitPicker: OutfitPickerProtocol, @unchecked Sendable {
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let fileManager: FileManagerProtocol

    public init(
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol = CacheService(),
        fileManager: FileManagerProtocol
    ) {
        self.configService = configService
        self.cacheService = cacheService
        self.fileManager = fileManager
    }

    /// Creates a default OutfitPicker with automatic service setup.
    ///
    /// This is the recommended initializer for most use cases. It automatically
    /// configures file-based services that store data in the user's application
    /// support directory. No additional setup required.
    ///
    /// - Parameter fileManager: File manager for filesystem operations. Defaults to `FileManager.default`.
    public init(fileManager: FileManagerProtocol = FileManager.default) {
        self.configService = ConfigService(fileManager: fileManager)
        self.cacheService = CacheService(fileManager: fileManager)
        self.fileManager = fileManager
    }

    // MARK: - Core Operations

    public func showRandomOutfit(from categoryName: String) async throws
        -> OutfitReference?
    {
        guard
            !categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Category name cannot be empty"
            )
        }

        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard !files.isEmpty else { return nil }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let pool: [FileEntry]
            if categoryCache.wornOutfits.count >= files.count {
                let reset = CategoryCache(totalOutfits: files.count)
                try cacheService.save(
                    cache.updating(category: categoryName, with: reset)
                )
                pool = files
            } else {
                pool = files.filter {
                    !categoryCache.wornOutfits.contains($0.fileName)
                }
            }

            let file = pool.randomElement()!
            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            return OutfitReference(
                fileName: file.fileName,
                category: categoryRef
            )
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func showRandomOutfitAcrossCategories() async throws
        -> OutfitReference?
    {
        do {
            let config = try configService.load()
            let categoryInfos = try getCategoryInfo(config: config)

            var availableCategories = [(String, String, [FileEntry])]()

            for info in categoryInfos {
                guard case .hasOutfits = info.state else { continue }

                let categoryPath = URL(
                    filePath: config.root,
                    directoryHint: .isDirectory
                )
                .appending(
                    path: info.category.name,
                    directoryHint: .isDirectory
                )
                .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                guard !files.isEmpty else { continue }

                let cache = try cacheService.load()
                let categoryCache =
                    cache.categories[info.category.name]
                    ?? CategoryCache(totalOutfits: files.count)
                let availableFiles = files.filter {
                    !categoryCache.wornOutfits.contains($0.fileName)
                }

                if !availableFiles.isEmpty {
                    availableCategories.append(
                        (info.category.name, categoryPath, availableFiles)
                    )
                }
            }

            guard !availableCategories.isEmpty else { return nil }

            let (categoryName, categoryPath, files) =
                availableCategories.randomElement()!
            let file = files.randomElement()!
            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            return OutfitReference(
                fileName: file.fileName,
                category: categoryRef
            )
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func showAllWornOutfits() async throws -> [String: [String]] {
        try cacheService.load().categories.compactMapValues { category in
            guard !category.wornOutfits.isEmpty else {
                return nil
            }
            return category.wornOutfits.sorted()
        }
    }

    public func showAllUnwornOutfits() async throws -> [String: [String]] {
        try cacheService.load().categories.compactMap {
            categoryName,
            categoryCache in
            let allFiles = try getAvatarFiles(in: categoryName).map(\.fileName)
            let unworn = allFiles.filter {
                !categoryCache.wornOutfits.contains($0)
            }
            return unworn.isEmpty ? nil : (categoryName, unworn.sorted())
        }
        .reduce(into: [:]) { result, element in
            result[element.0] = element.1
        }
    }

    public func wearOutfit(_ outfit: OutfitReference) async throws {
        guard
            !outfit.fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Outfit filename cannot be empty"
            )
        }
        guard
            !outfit.category.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Category name cannot be empty"
            )
        }

        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: outfit.category.name, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard files.contains(where: { $0.fileName == outfit.fileName })
            else {
                throw OutfitPickerError.noOutfitsAvailable
            }

            let cache = try cacheService.load()
            var categoryCache =
                cache.categories[outfit.category.name]
                ?? CategoryCache(totalOutfits: files.count)

            if !categoryCache.wornOutfits.contains(outfit.fileName) {
                categoryCache = categoryCache.adding(outfit.fileName)
                let updatedOutfitCache = cache.updating(
                    category: outfit.category.name,
                    with: categoryCache
                )
                try cacheService.save(updatedOutfitCache)

                // Check if this completes the rotation
                if categoryCache.wornOutfits.count >= files.count {
                    // Reset the category
                    let resetCache = CategoryCache(totalOutfits: files.count)
                    let updatedOutfitCache = cache.updating(
                        category: outfit.category.name,
                        with: resetCache
                    )
                    try cacheService.save(updatedOutfitCache)
                    // Notify client that rotation completed and category was reset
                    throw OutfitPickerError.rotationCompleted(
                        category: outfit.category.name
                    )
                } else {
                    let updatedOutfitCache = cache.updating(
                        category: outfit.category.name,
                        with: categoryCache
                    )
                    try cacheService.save(updatedOutfitCache)
                }
            }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getCategoryInfo() async throws -> [CategoryInfo] {
        do {
            let config = try configService.load()
            return try getCategoryInfo(config: config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getCategories() async throws -> [CategoryReference] {
        do {
            let config = try configService.load()
            let infos = try getCategoryInfo(config: config)

            return infos.compactMap { info -> CategoryReference? in
                if case .hasOutfits = info.state {
                    return info.category
                }
                return nil
            }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getAvailableCount(for categoryName: String) async throws -> Int {
        guard
            !categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Category name cannot be empty"
            )
        }

        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let availableFiles = files.filter {
                !categoryCache.wornOutfits.contains($0.fileName)
            }
            return categoryCache.isRotationComplete
                ? files.count : availableFiles.count
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetCategory(_ categoryName: String) async throws {
        guard
            !categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Category name cannot be empty"
            )
        }

        do {
            _ = try configService.load()
            let cache = try cacheService.load()
            let updatedCache = cache.removing(category: categoryName)
            try cacheService.save(updatedCache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetAllCategories() async throws {
        do {
            _ = try configService.load()
            try cacheService.save(OutfitCache())
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func partialReset(categoryName: String, wornCount: Int) async throws {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard wornCount < files.count else { return }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let wornOutfits = Array(categoryCache.wornOutfits.prefix(wornCount))
            let updatedCache = CategoryCache(
                wornOutfits: Set(wornOutfits),
                totalOutfits: files.count
            )
            let updatedOutfitCache = cache.updating(
                category: categoryName,
                with: updatedCache
            )
            try cacheService.save(updatedOutfitCache)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func showAllOutfits(from categoryName: String) async throws
        -> [OutfitReference]
    {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            return files.map {
                OutfitReference(fileName: $0.fileName, category: categoryRef)
            }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func detectChanges() async throws -> CategoryChanges {
        do {
            let config = try configService.load()
            return try detectChanges(config: config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func updateConfig(with changes: CategoryChanges) async throws {
        do {
            let config = try configService.load()
            let updatedConfig = try createUpdatedConfig(
                from: config,
                with: changes
            )
            try configService.save(updatedConfig)

            if !changes.deletedCategories.isEmpty {
                var cache = try cacheService.load()
                for _ in changes.deletedCategories {
                    cache = cache.resetAll()
                }
                try cacheService.save(cache)
            }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func wearOutfits(_ outfits: [OutfitReference]) async throws {
        guard !outfits.isEmpty else {
            try cacheService.save(try cacheService.load())
            return
        }

        for outfit in outfits {
            guard
                !outfit.fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            else {
                throw OutfitPickerError.invalidInput(
                    "Outfit filename cannot be empty"
                )
            }
            guard
                !outfit.category.name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            else {
                throw OutfitPickerError.invalidInput(
                    "Category name cannot be empty"
                )
            }
        }

        do {
            let config = try configService.load()
            var cache = try cacheService.load()

            for outfit in outfits {
                let categoryPath = URL(
                    filePath: config.root,
                    directoryHint: .isDirectory
                )
                .appending(
                    path: outfit.category.name,
                    directoryHint: .isDirectory
                )
                .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                guard files.contains(where: { $0.fileName == outfit.fileName })
                else {
                    throw OutfitPickerError.noOutfitsAvailable
                }

                var categoryCache =
                    cache.categories[outfit.category.name]
                    ?? CategoryCache(totalOutfits: files.count)

                if !categoryCache.wornOutfits.contains(outfit.fileName) {
                    categoryCache = categoryCache.adding(outfit.fileName)
                    cache = cache.updating(
                        category: outfit.category.name,
                        with: categoryCache
                    )
                }
            }

            try cacheService.save(cache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetCategories(_ categoryNames: [String]) async throws {
        guard !categoryNames.isEmpty else {
            try cacheService.save(try cacheService.load())
            return
        }

        for categoryName in categoryNames {
            guard
                !categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            else {
                throw OutfitPickerError.invalidInput(
                    "Category name cannot be empty"
                )
            }
        }

        do {
            _ = try configService.load()
            var cache = try cacheService.load()

            for categoryName in categoryNames {
                cache = cache.removing(category: categoryName)
            }

            try cacheService.save(cache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func searchOutfits(pattern: String) async throws -> [OutfitReference] {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Search pattern cannot be empty"
            )
        }

        do {
            let config = try configService.load()
            let categoryInfos = try getCategoryInfo(config: config)
            var results: [OutfitReference] = []

            for info in categoryInfos {
                guard case .hasOutfits = info.state else { continue }

                let categoryPath = URL(
                    filePath: config.root,
                    directoryHint: .isDirectory
                )
                .appending(
                    path: info.category.name,
                    directoryHint: .isDirectory
                )
                .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                let categoryRef = CategoryReference(
                    name: info.category.name,
                    path: categoryPath
                )

                let matchingFiles = files.filter { file in
                    file.fileName.localizedCaseInsensitiveContains(pattern)
                }

                results.append(
                    contentsOf: matchingFiles.map {
                        OutfitReference(
                            fileName: $0.fileName,
                            category: categoryRef
                        )
                    }
                )
            }

            return results.sorted { $0.fileName < $1.fileName }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func filterCategories(pattern: String) async throws
        -> [CategoryReference]
    {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw OutfitPickerError.invalidInput(
                "Filter pattern cannot be empty"
            )
        }

        do {
            let categories = try await getCategories()
            return categories.filter { category in
                category.name.localizedCaseInsensitiveContains(pattern)
            }.sorted { $0.name < $1.name }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    // MARK: - Convenience Methods

    /// Checks if a specific outfit exists in a category.
    public func outfitExists(_ fileName: String, in categoryName: String)
        async throws -> Bool
    {
        let outfits = try await showAllOutfits(from: categoryName)
        return outfits.contains { $0.fileName == fileName }
    }

    /// Checks if a specific outfit has been worn.
    public func isOutfitWorn(_ fileName: String, in categoryName: String)
        async throws -> Bool
    {
        do {
            let cache = try cacheService.load()
            let categoryCache = cache.categories[categoryName]
            return categoryCache?.wornOutfits.contains(fileName) ?? false
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Gets a specific outfit reference by name.
    public func getOutfit(_ fileName: String, from categoryName: String)
        async throws
        -> OutfitReference?
    {
        let outfits = try await showAllOutfits(from: categoryName)
        return outfits.first { $0.fileName == fileName }
    }

    /// Gets the rotation progress for a category as (worn, total) counts.
    public func getRotationProgress(for categoryName: String) async throws -> (
        worn: Int, total: Int
    ) {
        let available = try await getAvailableCount(for: categoryName)
        let total = try await showAllOutfits(from: categoryName).count
        let worn = total - available
        return (worn: worn, total: total)
    }

    /// Gets the rotation progress for a category (0.0 to 1.0).
    public func getRotationProgressPercentage(for categoryName: String)
        async throws -> Double
    {
        let (worn, total) = try await getRotationProgress(for: categoryName)
        guard total > 0 else { return 1.0 }
        return Double(worn) / Double(total)
    }

    // MARK: - Private Helper Methods

    private func getAvatarFiles(in directoryPath: String) throws -> [FileEntry] {
        let url = URL(filePath: directoryPath, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: []
        )

        return contents.compactMap { fileURL in
            guard !fileURL.hasDirectoryPath,
                fileURL.pathExtension.lowercased() == "avatar"
            else {
                return nil
            }
            return FileEntry(filePath: fileURL.path(percentEncoded: false))
        }.sorted(by: { $0.fileName < $1.fileName })
    }

    private func getCategoryInfo(config: Config) throws -> [CategoryInfo] {
        let rootURL = URL(filePath: config.root, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: []
        )

        var categoryInfos = [CategoryInfo]()

        for url in contents {
            var isDirectory: ObjCBool = false
            guard
                fileManager.fileExists(
                    atPath: url.path(percentEncoded: false),
                    isDirectory: &isDirectory
                ),
                isDirectory.boolValue
            else { continue }

            let categoryName = url.lastPathComponent
            let categoryPath = url.path(percentEncoded: false)
            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )

            if config.excludedCategories.contains(categoryName) {
                categoryInfos.append(
                    CategoryInfo(
                        category: categoryRef,
                        state: .userExcluded,
                        outfitCount: 0
                    )
                )
                continue
            }

            let avatarFiles = try getAvatarFiles(in: categoryPath)
            let allFiles = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            )
            .filter { !$0.hasDirectoryPath }

            let state: CategoryState
            if avatarFiles.isEmpty {
                state = allFiles.isEmpty ? .empty : .noAvatarFiles
            } else {
                state = .hasOutfits
            }

            categoryInfos.append(
                CategoryInfo(
                    category: categoryRef,
                    state: state,
                    outfitCount: avatarFiles.count
                )
            )
        }

        return categoryInfos.sorted { $0.category.name < $1.category.name }
    }

    private func detectChanges(config: Config) throws -> CategoryChanges {
        let currentCategoryInfos = try getCategoryInfo(config: config)

        var currentCategoryFiles = [String: Set<String>]()
        for info in currentCategoryInfos {
            let avatarFiles = try getAvatarFiles(in: info.category.path)
            currentCategoryFiles[info.category.name] = Set(
                avatarFiles.map(\.fileName)
            )
        }

        let previousCategoryFiles = config.knownCategoryFiles

        let previousCategoryNames: Set<String>
        if !previousCategoryFiles.isEmpty {
            previousCategoryNames = Set(previousCategoryFiles.keys)
        } else {
            previousCategoryNames = config.knownCategories
        }

        let currentCategoryNames = Set(currentCategoryFiles.keys)

        let newCategories = currentCategoryNames.subtracting(
            previousCategoryNames
        )
        let deletedCategories = previousCategoryNames.subtracting(
            currentCategoryNames
        )

        var changedCategories = Set<String>()
        var addedFiles = [String: Set<String>]()
        var deletedFiles = [String: Set<String>]()

        let commonCategories = currentCategoryNames.intersection(
            previousCategoryNames
        )

        for category in commonCategories {
            let previousFiles = previousCategoryFiles[category] ?? []
            let currentFiles = currentCategoryFiles[category]!

            let added = currentFiles.subtracting(previousFiles)
            let deleted = previousFiles.subtracting(currentFiles)

            if !added.isEmpty || !deleted.isEmpty {
                changedCategories.insert(category)
                if !added.isEmpty {
                    addedFiles[category] = added
                }
                if !deleted.isEmpty {
                    deletedFiles[category] = deleted
                }
            }
        }

        return CategoryChanges(
            newCategories: newCategories,
            deletedCategories: deletedCategories,
            changedCategories: changedCategories,
            addedFiles: addedFiles,
            deletedFiles: deletedFiles
        )
    }

    private func createUpdatedConfig(
        from config: Config,
        with changes: CategoryChanges
    ) throws
        -> Config
    {
        let currentCategoryInfos = try getCategoryInfo(config: config)
        let updatedKnownCategories = Set(
            currentCategoryInfos.map { $0.category.name }
        )

        var updatedKnownCategoryFiles: [String: Set<String>] = [:]
        for info in currentCategoryInfos {
            let avatarFiles = try getAvatarFiles(in: info.category.path)
            updatedKnownCategoryFiles[info.category.name] = Set(
                avatarFiles.map(\.fileName)
            )
        }

        return try Config(
            root: config.root,
            language: config.language,
            excludedCategories: config.excludedCategories,
            knownCategories: updatedKnownCategories,
            knownCategoryFiles: updatedKnownCategoryFiles
        )
    }
}

// MARK: - Type-Safe CategoryReference Default Implementations

extension OutfitPickerProtocol {
    public func showRandomOutfit(from category: CategoryReference) async throws
        -> OutfitReference?
    {
        return try await showRandomOutfit(from: category.name)
    }

    public func getAvailableCount(for category: CategoryReference) async throws
        -> Int
    {
        return try await getAvailableCount(for: category.name)
    }

    public func resetCategory(_ category: CategoryReference) async throws {
        try await resetCategory(category.name)
    }

    public func partialReset(category: CategoryReference, wornCount: Int)
        async throws
    {
        try await partialReset(
            categoryName: category.name,
            wornCount: wornCount
        )
    }

    public func showAllOutfits(from category: CategoryReference) async throws
        -> [OutfitReference]
    {
        return try await showAllOutfits(from: category.name)
    }

    public func getRotationProgress(for category: CategoryReference)
        async throws -> (
            worn: Int, total: Int
        )
    {
        return try await getRotationProgress(for: category.name)
    }
}
