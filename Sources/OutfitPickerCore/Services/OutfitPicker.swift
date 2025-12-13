import Foundation

/// Manages outfit selection and rotation across categories.
public protocol OutfitPickerProtocol: Sendable {
    func showRandomOutfit(from categoryName: String) async throws -> OutfitReference?
    func showRandomOutfitAcrossCategories() async throws -> OutfitReference?
    func showAllWornOutfits() async throws -> [String: [String]]
    func wearOutfit(_ outfit: OutfitReference) async throws
    func getCategoryInfo() async throws -> [CategoryInfo]
    func getCategories() async throws -> [CategoryReference]
    func resetCategory(_ categoryName: String) async throws
    func resetAllCategories() async throws
    func showAllOutfits(from categoryName: String) async throws -> [OutfitReference]
    func isOutfitWorn(_ fileName: String, in categoryName: String) async throws -> Bool
    func getRootDirectory() async throws -> String
    func getConfiguration() async throws -> Config
    func updateConfiguration(_ config: Config) async throws
    func factoryReset() async throws
}

public protocol FileManagerProtocol: Sendable {
    func contentsOfDirectory(
        at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL]
    func createDirectory(
        at url: URL, withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?) throws
    func removeItem(at URL: URL) throws
}

extension FileManager: FileManagerProtocol {}

public actor OutfitPicker: OutfitPickerProtocol {
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol = CacheService(),
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.configService = configService
        self.cacheService = cacheService
        self.categoryRepository = categoryRepository
    }

    public init(fileManager: FileManagerProtocol = FileManager.default) {
        self.configService = ConfigService(fileManager: fileManager)
        self.cacheService = CacheService(fileManager: fileManager)
        let categoryScanner = CategoryScanner(fileManager: fileManager)
        self.categoryRepository = CategoryRepository(
            categoryScanner: categoryScanner,
            cacheManager: CacheManager()
        )
    }

    public func showRandomOutfit(from categoryName: String) async throws -> OutfitReference? {
        try BusinessRules.validateCategoryName(categoryName)
        do {
            let (config, cache) = try await loadConfigAndCache()
            let categoryPath = buildCategoryPath(config.root, categoryName)
            let files = try await categoryRepository.getOutfits(in: categoryPath)
            guard !files.isEmpty else { return nil }

            let categoryCache =
                cache.categories[categoryName] ?? CategoryCache(totalOutfits: files.count)
            let pool = try await getAvailablePool(
                files: files, categoryCache: categoryCache, categoryName: categoryName, cache: cache
            )

            guard let file = OutfitSelection.selectRandom(from: pool) else { return nil }
            return OutfitReference(
                fileName: file.fileName,
                category: CategoryReference(name: categoryName, path: categoryPath))
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func showRandomOutfitAcrossCategories() async throws -> OutfitReference? {
        do {
            let (config, cache) = try await loadConfigAndCache()
            let categoryInfos = try await categoryRepository.getCategories(
                in: config.root, excludedCategories: config.excludedCategories)

            let hasOutfitsInfos = categoryInfos.filter { info in
                if case .hasOutfits = info.state { return true }
                return false
            }

            let availableCategories = try await withThrowingTaskGroup(
                of: (String, String, [FileEntry])?.self
            ) { group in
                for info in hasOutfitsInfos {
                    let categoryPath = buildCategoryPath(config.root, info.category.name)
                    let categoryName = info.category.name
                    let categoryCache =
                        cache.categories[categoryName] ?? CategoryCache(totalOutfits: 0)

                    group.addTask { [categoryRepository] in
                        let files = try await categoryRepository.getOutfits(in: categoryPath)
                        guard !files.isEmpty else { return nil }

                        let availableFiles = BusinessRules.filterAvailableOutfits(
                            from: files,
                            wornOutfits: categoryCache.wornOutfits
                        )
                        return availableFiles.isEmpty
                            ? nil : (categoryName, categoryPath, availableFiles)
                    }
                }

                var results: [(String, String, [FileEntry])] = []
                for try await result in group {
                    if let result = result {
                        results.append(result)
                    }
                }
                return results
            }

            guard !availableCategories.isEmpty else { return nil }
            let (categoryName, categoryPath, files) = availableCategories.randomElement()!
            let file = files.randomElement()!
            return OutfitReference(
                fileName: file.fileName,
                category: CategoryReference(name: categoryName, path: categoryPath))
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func showAllWornOutfits() async throws -> [String: [String]] {
        do {
            return try cacheService.load().categories.compactMapValues { category in
                category.wornOutfits.isEmpty ? nil : category.wornOutfits.sorted()
            }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func wearOutfit(_ outfit: OutfitReference) async throws {
        try BusinessRules.validateOutfit(outfit)
        do {
            let (config, cache) = try await loadConfigAndCache()
            let categoryPath = buildCategoryPath(config.root, outfit.category.name)
            let files = try await categoryRepository.getOutfits(in: categoryPath)

            guard files.contains(where: { $0.fileName == outfit.fileName }) else {
                throw OutfitPickerError.noOutfitsAvailable
            }

            var categoryCache =
                cache.categories[outfit.category.name] ?? CategoryCache(totalOutfits: files.count)
            guard !categoryCache.wornOutfits.contains(outfit.fileName) else { return }

            categoryCache = categoryCache.adding(outfit.fileName)
            try cacheService.save(
                cache.updating(category: outfit.category.name, with: categoryCache))

            if BusinessRules.shouldResetRotation(
                wornCount: categoryCache.wornOutfits.count, totalCount: files.count)
            {
                let resetCache = CategoryCache(totalOutfits: files.count)
                try cacheService.save(
                    cache.updating(category: outfit.category.name, with: resetCache))
                throw OutfitPickerError.rotationCompleted(category: outfit.category.name)
            }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getCategoryInfo() async throws -> [CategoryInfo] {
        do {
            let config = try configService.load()
            return try await categoryRepository.getCategories(
                in: config.root, excludedCategories: config.excludedCategories)
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getCategories() async throws -> [CategoryReference] {
        do {
            let config = try configService.load()
            let infos = try await categoryRepository.getCategories(
                in: config.root, excludedCategories: config.excludedCategories)
            return infos.compactMap { info in
                if case .hasOutfits = info.state { return info.category }
                return nil
            }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func resetCategory(_ categoryName: String) async throws {
        try BusinessRules.validateCategoryName(categoryName)
        do {
            _ = try configService.load()
            let cache = try cacheService.load()
            try cacheService.save(cache.removing(category: categoryName))
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func resetAllCategories() async throws {
        do {
            _ = try configService.load()
            try cacheService.save(OutfitCache())
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func showAllOutfits(from categoryName: String) async throws -> [OutfitReference] {
        do {
            let config = try configService.load()
            let categoryPath = buildCategoryPath(config.root, categoryName)
            let files = try await categoryRepository.getOutfits(in: categoryPath)
            let categoryRef = CategoryReference(name: categoryName, path: categoryPath)
            return files.map { OutfitReference(fileName: $0.fileName, category: categoryRef) }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func isOutfitWorn(_ fileName: String, in categoryName: String) async throws -> Bool {
        do {
            let cache = try cacheService.load()
            return cache.categories[categoryName]?.wornOutfits.contains(fileName) ?? false
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    // MARK: - Helper Methods

    private func buildCategoryPath(_ root: String, _ categoryName: String) -> String {
        URL(filePath: root, directoryHint: .isDirectory)
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)
    }

    private func loadConfigAndCache() async throws -> (Config, OutfitCache) {
        let config = try configService.load()
        let cache = try cacheService.load()
        return (config, cache)
    }

    private func getAvailablePool(
        files: [FileEntry], categoryCache: CategoryCache, categoryName: String, cache: OutfitCache
    ) async throws -> [FileEntry] {
        if BusinessRules.shouldResetRotation(
            wornCount: categoryCache.wornOutfits.count, totalCount: files.count)
        {
            let reset = CategoryCache(totalOutfits: files.count)
            try cacheService.save(cache.updating(category: categoryName, with: reset))
            return files
        } else {
            return BusinessRules.filterAvailableOutfits(
                from: files, wornOutfits: categoryCache.wornOutfits)
        }
    }

}

// MARK: - CLI Extensions

extension OutfitPicker {
    public func getAvailableOutfits(from categoryName: String) async throws -> [OutfitReference] {
        let allOutfits = try await showAllOutfits(from: categoryName)
        var availableOutfits: [OutfitReference] = []
        for outfit in allOutfits {
            if !(try await isOutfitWorn(outfit.fileName, in: categoryName)) {
                availableOutfits.append(outfit)
            }
        }
        return availableOutfits
    }

    public func getWornOutfits(from categoryName: String) async throws -> [OutfitReference] {
        let allOutfits = try await showAllOutfits(from: categoryName)
        var wornOutfits: [OutfitReference] = []
        for outfit in allOutfits {
            if try await isOutfitWorn(outfit.fileName, in: categoryName) {
                wornOutfits.append(outfit)
            }
        }
        return wornOutfits
    }

    public func getAllOutfitStates() async throws -> [String: CategoryOutfitState] {
        let categories = try await getCategories()
        var states: [String: CategoryOutfitState] = [:]
        for category in categories {
            states[category.name] = try await getOutfitState(for: category.name)
        }
        return states
    }

    public func getOutfitState(for categoryName: String) async throws -> CategoryOutfitState {
        guard let category = try await getCategories().first(where: { $0.name == categoryName })
        else {
            throw OutfitPickerError.categoryNotFound
        }
        let allOutfits = try await showAllOutfits(from: category.name)
        let availableOutfits = try await getAvailableOutfits(from: categoryName)
        let wornOutfits = try await getWornOutfits(from: categoryName)
        return CategoryOutfitState(
            category: category, allOutfits: allOutfits, availableOutfits: availableOutfits,
            wornOutfits: wornOutfits)
    }

    public func getAllAvailableOutfitsWithKeys() async throws -> [(
        key: String, outfit: OutfitReference
    )] {
        let states = try await getAllOutfitStates()
        var results: [(key: String, outfit: OutfitReference)] = []
        for (categoryName, state) in states {
            for outfit in state.availableOutfits {
                results.append((key: "\(categoryName)/\(outfit.fileName)", outfit: outfit))
            }
        }
        return results.sorted { $0.key < $1.key }
    }

    public func isWorn(_ outfit: OutfitReference) async throws -> Bool {
        try await isOutfitWorn(outfit.fileName, in: outfit.category.name)
    }

    public func getAvailableOutfits(from category: CategoryReference) async throws
        -> [OutfitReference]
    {
        try await getAvailableOutfits(from: category.name)
    }

    public func getWornOutfits(from category: CategoryReference) async throws -> [OutfitReference] {
        try await getWornOutfits(from: category.name)
    }

    public func getOutfitState(for category: CategoryReference) async throws -> CategoryOutfitState
    {
        try await getOutfitState(for: category.name)
    }

    public func getRootDirectory() async throws -> String {
        let (config, _) = try await loadConfigAndCache()
        return config.root
    }

    public func getConfiguration() async throws -> Config {
        let (config, _) = try await loadConfigAndCache()
        return config
    }

    public func updateConfiguration(_ config: Config) async throws {
        try configService.save(config)
        await categoryRepository.invalidateCache()
    }

    public func factoryReset() async throws {
        try configService.delete()
        try cacheService.delete()
        await categoryRepository.invalidateCache()
    }
}

// MARK: - Factory Extensions

extension OutfitPicker {
    public static func create(
        outfitDirectory: String, fileManager: sending FileManagerProtocol = FileManager.default
    ) async throws -> OutfitPicker {
        let config = try Config(root: outfitDirectory)
        let configService = ConfigService(fileManager: fileManager)
        try configService.save(config)
        let categoryScanner = CategoryScanner(fileManager: fileManager)
        let categoryRepository = CategoryRepository(
            categoryScanner: categoryScanner,
            cacheManager: CacheManager()
        )
        return OutfitPicker(configService: configService, categoryRepository: categoryRepository)
    }

    public static func fromExistingConfig(
        fileManager: sending FileManagerProtocol = FileManager.default
    ) async throws -> OutfitPicker {
        let configService = ConfigService(fileManager: fileManager)
        _ = try configService.load()
        let categoryScanner = CategoryScanner(fileManager: fileManager)
        let categoryRepository = CategoryRepository(
            categoryScanner: categoryScanner,
            cacheManager: CacheManager()
        )
        return OutfitPicker(configService: configService, categoryRepository: categoryRepository)
    }

    public static func create(
        configuring builder: (ConfigBuilder) -> ConfigBuilder,
        fileManager: sending FileManagerProtocol = FileManager.default
    ) async throws -> OutfitPicker {
        let config = try builder(ConfigBuilder()).build()
        let configService = ConfigService(fileManager: fileManager)
        try configService.save(config)
        let categoryScanner = CategoryScanner(fileManager: fileManager)
        let categoryRepository = CategoryRepository(
            categoryScanner: categoryScanner,
            cacheManager: CacheManager()
        )
        return OutfitPicker(configService: configService, categoryRepository: categoryRepository)
    }
}
