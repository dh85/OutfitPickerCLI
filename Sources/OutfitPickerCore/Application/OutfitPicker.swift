import Foundation

public actor OutfitPicker: OutfitPickerProtocol {
    private let pickOutfitUseCase: PickOutfitUseCase
    private let wearOutfitUseCase: WearOutfitUseCase
    private let getCategoriesUseCase: GetCategoriesUseCase
    private let resetCategoryUseCase: ResetCategoryUseCase

    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let repository: CategoryRepositoryProtocol

    // Session state for tracking shown outfits
    private var globalShownOutfits: Set<String> = []
    private var categoryShownOutfits: [String: Set<String>] = [:]

    public init(
        config: Config,
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol,
        repository: CategoryRepositoryProtocol
    ) {
        self.configService = configService
        self.cacheService = cacheService
        self.repository = repository

        self.pickOutfitUseCase = PickOutfitUseCase(
            repository: repository,
            configService: configService,
            cacheService: cacheService
        )
        self.wearOutfitUseCase = WearOutfitUseCase(
            repository: repository,
            configService: configService,
            cacheService: cacheService
        )
        self.getCategoriesUseCase = GetCategoriesUseCase(
            repository: repository,
            configService: configService
        )
        self.resetCategoryUseCase = ResetCategoryUseCase(
            configService: configService,
            cacheService: cacheService
        )
    }

    public init(config: Config) {
        let fileManager = FileManager.default
        self.configService = ConfigService(fileManager: fileManager)
        self.cacheService = CacheService(fileManager: fileManager)
        let categoryScanner = CategoryScanner(fileManager: fileManager)
        self.repository = CategoryRepository(
            categoryScanner: categoryScanner, cacheManager: CacheManager())

        self.pickOutfitUseCase = PickOutfitUseCase(
            repository: repository,
            configService: configService,
            cacheService: cacheService
        )
        self.wearOutfitUseCase = WearOutfitUseCase(
            repository: repository,
            configService: configService,
            cacheService: cacheService
        )
        self.getCategoriesUseCase = GetCategoriesUseCase(
            repository: repository,
            configService: configService
        )
        self.resetCategoryUseCase = ResetCategoryUseCase(
            configService: configService,
            cacheService: cacheService
        )
    }

    public static func fromExistingConfig() async throws -> OutfitPicker {
        let configService = ConfigService()
        let config = try configService.load()
        return OutfitPicker(config: config)
    }

    public func showRandomOutfit(from categoryName: String) async throws -> OutfitReference? {
        do {
            return try await pickOutfitUseCase.execute(request: .init(categoryName: categoryName))
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func wearOutfit(_ outfit: OutfitReference) async throws {
        do {
            try await wearOutfitUseCase.execute(request: .init(outfit: outfit))
            // Reset session tracking when an outfit is worn
            globalShownOutfits.removeAll()
            categoryShownOutfits[outfit.category.name]?.removeAll()
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getCategoryInfo() async throws -> [CategoryInfo] {
        do {
            return try await getCategoriesUseCase.execute()
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getCategories() async throws -> [CategoryReference] {
        do {
            let infos = try await getCategoriesUseCase.execute()
            return infos.compactMap { info in
                if case .hasOutfits = info.state { return info.category }
                return nil
            }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func resetCategory(_ categoryName: String) async throws {
        do {
            try await resetCategoryUseCase.execute(categoryName: categoryName)
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func resetAllCategories() async throws {
        do {
            try await resetCategoryUseCase.executeAll()
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getRootDirectory() async throws -> String {
        do {
            return try configService.load().root
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getConfiguration() async throws -> Config {
        do {
            return try configService.load()
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func updateConfiguration(_ config: Config) async throws {
        do {
            try configService.save(config)
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func factoryReset() async throws {
        do {
            try configService.delete()
            try cacheService.delete()
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public static func create(_ configure: (ConfigBuilder) -> ConfigBuilder) async throws
        -> OutfitPicker
    {
        let builder = ConfigBuilder()
        let configuredBuilder = configure(builder)
        let config = try configuredBuilder.build()
        return OutfitPicker(config: config)
    }

    public func getOutfitState(for categoryName: String) async throws -> CategoryOutfitState {
        do {
            let config = try configService.load()
            let categoryPath = (config.root as NSString).appendingPathComponent(categoryName)
            let category = CategoryReference(name: categoryName, path: categoryPath)
            return try await getOutfitState(for: category)
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getAvailableOutfits(from categoryName: String) async throws -> [OutfitReference] {
        do {
            return try await getOutfitState(for: categoryName).availableOutfits
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getWornOutfits(from category: CategoryReference) async throws -> [OutfitReference] {
        do {
            return try await getOutfitState(for: category).wornOutfits
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getWornOutfits(from categoryName: String) async throws -> [OutfitReference] {
        do {
            return try await getOutfitState(for: categoryName).wornOutfits
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func isWorn(_ outfit: OutfitReference) async throws -> Bool {
        do {
            return try await isOutfitWorn(outfit.fileName, in: outfit.category.name)
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getOutfitState(for category: CategoryReference) async throws -> CategoryOutfitState
    {
        do {
            let config = try configService.load()
            let cache = try cacheService.load()

            let categoryPath = (config.root as NSString).appendingPathComponent(category.name)
            let files = try await repository.getOutfits(in: categoryPath)

            let categoryCache =
                cache.categories[category.name] ?? CategoryCache(totalOutfits: files.count)

            let allOutfits = files.map { file in
                OutfitReference(fileName: file.fileName, category: category)
            }

            let wornFileNames = Set(categoryCache.wornOutfits)
            let wornOutfits = allOutfits.filter { wornFileNames.contains($0.fileName) }
            let availableOutfits = allOutfits.filter { !wornFileNames.contains($0.fileName) }

            return CategoryOutfitState(
                category: category,
                allOutfits: allOutfits,
                availableOutfits: availableOutfits,
                wornOutfits: wornOutfits
            )
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getAllOutfitStates() async throws -> [String: CategoryOutfitState] {
        do {
            let categories = try await getCategories()
            var states: [String: CategoryOutfitState] = [:]

            for category in categories {
                states[category.name] = try await getOutfitState(for: category)
            }
            return states
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getAvailableOutfits(from category: CategoryReference) async throws
        -> [OutfitReference]
    {
        do {
            return try await getOutfitState(for: category).availableOutfits
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func getAllAvailableOutfitsWithKeys() async throws -> [(
        key: String, outfit: OutfitReference
    )] {
        do {
            let states = try await getAllOutfitStates()
            var result: [(key: String, outfit: OutfitReference)] = []

            for (categoryName, state) in states {
                for outfit in state.availableOutfits {
                    result.append((key: "\(categoryName)/\(outfit.fileName)", outfit: outfit))
                }
            }
            return result.sorted { $0.key < $1.key }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func showAllOutfits(from categoryName: String) async throws -> [OutfitReference] {
        do {
            let config = try configService.load()
            let categoryPath = (config.root as NSString).appendingPathComponent(categoryName)
            let files = try await repository.getOutfits(in: categoryPath)
            return files.map { file in
                OutfitReference(
                    fileName: file.fileName,
                    category: CategoryReference(name: categoryName, path: categoryPath)
                )
            }
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

    public func showAllWornOutfits() async throws -> [String: [String]] {
        do {
            return try cacheService.load().categories.compactMapValues { category in
                category.wornOutfits.isEmpty ? nil : category.wornOutfits.sorted()
            }
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    public func showRandomOutfitAcrossCategories() async throws -> OutfitReference? {
        do {
            let config = try configService.load()
            let cache = try cacheService.load()
            let categoryInfos = try await getCategoriesUseCase.execute()

            let hasOutfitsInfos = categoryInfos.filter { info in
                if case .hasOutfits = info.state { return true }
                return false
            }

            var availableCategories: [(String, String, [FileEntry])] = []

            for info in hasOutfitsInfos {
                let categoryPath = (config.root as NSString).appendingPathComponent(
                    info.category.name)
                let categoryName = info.category.name
                let categoryCache = cache.categories[categoryName] ?? CategoryCache(totalOutfits: 0)

                let files = try await repository.getOutfits(in: categoryPath)
                if files.isEmpty { continue }

                let availableFiles = BusinessRules.filterAvailableOutfits(
                    from: files,
                    wornOutfits: categoryCache.wornOutfits
                )

                if !availableFiles.isEmpty {
                    availableCategories.append((categoryName, categoryPath, availableFiles))
                }
            }

            guard !availableCategories.isEmpty else { return nil }
            guard let (categoryName, categoryPath, files) = availableCategories.randomElement()
            else { return nil }
            guard let file = files.randomElement() else { return nil }

            return OutfitReference(
                fileName: file.fileName,
                category: CategoryReference(name: categoryName, path: categoryPath))
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    // MARK: - Session Management

    /// Shows next unique random outfit across all categories, filtering out already shown outfits
    public func showNextUniqueRandomOutfit() async throws -> OutfitReference? {
        do {
            let config = try configService.load()
            let cache = try cacheService.load()
            let categoryInfos = try await getCategoriesUseCase.execute()

            let hasOutfitsInfos = categoryInfos.filter { info in
                if case .hasOutfits = info.state { return true }
                return false
            }

            var allAvailableOutfits: [(String, String, FileEntry)] = []

            for info in hasOutfitsInfos {
                let categoryPath = (config.root as NSString).appendingPathComponent(
                    info.category.name)
                let categoryName = info.category.name
                let categoryCache = cache.categories[categoryName] ?? CategoryCache(totalOutfits: 0)

                let files = try await repository.getOutfits(in: categoryPath)
                if files.isEmpty { continue }

                let availableFiles = BusinessRules.filterAvailableOutfits(
                    from: files,
                    wornOutfits: categoryCache.wornOutfits
                )

                for file in availableFiles {
                    allAvailableOutfits.append((categoryName, categoryPath, file))
                }
            }

            guard !allAvailableOutfits.isEmpty else { return nil }

            // Filter out shown outfits
            let unseenOutfits = allAvailableOutfits.filter { (categoryName, _, file) in
                let outfitKey = "\(categoryName)/\(file.fileName)"
                return !globalShownOutfits.contains(outfitKey)
            }

            // If all have been shown, reset and use all available
            let outfitsToChooseFrom: [(String, String, FileEntry)]
            if unseenOutfits.isEmpty {
                globalShownOutfits.removeAll()
                outfitsToChooseFrom = allAvailableOutfits
            } else {
                outfitsToChooseFrom = unseenOutfits
            }

            guard let (categoryName, categoryPath, file) = outfitsToChooseFrom.randomElement()
            else {
                return nil
            }

            // Mark as shown
            let outfitKey = "\(categoryName)/\(file.fileName)"
            globalShownOutfits.insert(outfitKey)

            return OutfitReference(
                fileName: file.fileName,
                category: CategoryReference(name: categoryName, path: categoryPath)
            )
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    /// Shows next unique random outfit from a specific category, filtering out already shown outfits
    public func showNextUniqueRandomOutfit(from categoryName: String) async throws
        -> OutfitReference?
    {
        do {
            let config = try configService.load()
            let cache = try cacheService.load()
            let categoryPath = (config.root as NSString).appendingPathComponent(categoryName)
            let categoryCache = cache.categories[categoryName] ?? CategoryCache(totalOutfits: 0)

            let files = try await repository.getOutfits(in: categoryPath)
            guard !files.isEmpty else { return nil }

            let availableFiles = BusinessRules.filterAvailableOutfits(
                from: files,
                wornOutfits: categoryCache.wornOutfits
            )

            guard !availableFiles.isEmpty else { return nil }

            // Get or create shown set for this category
            var shownInCategory = categoryShownOutfits[categoryName] ?? []

            // Filter out shown outfits
            let unseenOutfits = availableFiles.filter { file in
                !shownInCategory.contains(file.fileName)
            }

            // If all have been shown, reset for this category
            let outfitsToChooseFrom: [FileEntry]
            if unseenOutfits.isEmpty {
                shownInCategory.removeAll()
                outfitsToChooseFrom = availableFiles
            } else {
                outfitsToChooseFrom = unseenOutfits
            }

            guard let file = outfitsToChooseFrom.randomElement() else { return nil }

            // Mark as shown
            shownInCategory.insert(file.fileName)
            categoryShownOutfits[categoryName] = shownInCategory

            return OutfitReference(
                fileName: file.fileName,
                category: CategoryReference(name: categoryName, path: categoryPath)
            )
        } catch {
            throw ErrorMapper.mapError(error)
        }
    }

    /// Resets the global session, clearing all shown outfit tracking
    public func resetGlobalSession() async {
        globalShownOutfits.removeAll()
    }

    /// Resets the session for a specific category, clearing shown outfit tracking
    public func resetCategorySession(_ categoryName: String) async {
        categoryShownOutfits[categoryName]?.removeAll()
    }
}
