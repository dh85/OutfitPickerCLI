import Foundation

public protocol ConfigServiceProtocol: Sendable {
    func load() throws -> Config
    func save(_ config: Config) throws
    func delete() throws
    func configPath() throws -> URL
}

public struct ConfigService: ConfigServiceProtocol, @unchecked Sendable {
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
        do {
            return try fileService.filePath()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func load() throws -> Config {
        do {
            guard let config = try fileService.load() else {
                throw OutfitPickerError.configurationNotFound
            }
            return config
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func save(_ config: Config) throws {
        do {
            try fileService.save(config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func delete() throws {
        do {
            try fileService.delete()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }
}
