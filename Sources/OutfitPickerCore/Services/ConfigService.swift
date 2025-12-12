import Foundation

public protocol ConfigServiceProtocol: Sendable {
    func load() throws -> Config
    func save(_ config: Config) throws
    func delete() throws
    func configPath() throws -> URL
}

public struct ConfigService: ConfigServiceProtocol {
    private let fileService: FileService<Config>

    public init(
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider()
    ) {
        self.fileService = FileService(
            fileName: "config.json",
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: directoryProvider,
            errorMapper: { ConfigError.pathTraversalNotAllowed }
        )
    }

    public func configPath() throws -> URL {
        return try ErrorMapper.execute {
            return try fileService.filePath()
        }
    }

    public func load() throws -> Config {
        return try ErrorMapper.execute {
            guard let config = try fileService.load() else {
                throw OutfitPickerError.configurationNotFound
            }
            return config
        }
    }

    public func save(_ config: Config) throws {
        try ErrorMapper.execute {
            try fileService.save(config)
        }
    }

    public func delete() throws {
        try ErrorMapper.execute {
            try fileService.delete()
        }
    }
}
