import Foundation

public protocol CacheServiceProtocol: Sendable {
    func load() throws -> OutfitCache
    func save(_ cache: OutfitCache) throws
    func delete() throws
    func cachePath() throws -> URL
}

public struct CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let fileService: FileService<OutfitCache>

    public init(
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider()
    ) {
        self.fileService = FileService(
            fileName: "cache.json",
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: directoryProvider,
            errorMapper: { FileSystemError.directoryNotFound }
        )
    }

    public func cachePath() throws -> URL {
        do {
            return try fileService.filePath()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func load() throws -> OutfitCache {
        do {
            return try fileService.load() ?? OutfitCache()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func save(_ cache: OutfitCache) throws {
        do {
            try fileService.save(cache)
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
