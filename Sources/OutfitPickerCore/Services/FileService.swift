import Foundation

public protocol DataManagerProtocol {
    func data(contentsOf url: URL) throws -> Data
    func write(_ data: Data, to url: URL) throws
}

public struct DefaultDataManager: DataManagerProtocol {
    public init() {}

    public func data(contentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}

public protocol DirectoryProvider {
    func baseDirectory() throws -> URL
}

public struct DefaultDirectoryProvider: DirectoryProvider {
    private let fileManager: any FileManagerProtocol

    public init(fileManager: any FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    public func baseDirectory() throws -> URL {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            return URL(filePath: xdg, directoryHint: .isDirectory)
        }
        guard
            let appSup = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else { throw OutfitPickerError.invalidConfiguration }
        return appSup
    }
}

/// Generic file service for JSON persistence operations.
///
/// Provides type-safe loading, saving, and deletion of Codable objects
/// with configurable dependencies for testing and platform compatibility.
///
/// Example:
/// ```swift
/// let service = FileService<Config>(fileName: "config.json")
/// try service.save(myConfig)
/// let loaded = try service.load()
/// ```
public struct FileService<T: Codable>: @unchecked Sendable {
    private let fileManager: any FileManagerProtocol
    private let dataManager: DataManagerProtocol
    private let directoryProvider: DirectoryProvider
    private let fileName: String
    private let appName = "outfitpicker"
    private let errorMapper: @Sendable () -> Error

    /// Creates a new file service with configurable dependencies.
    /// - Parameters:
    ///   - fileName: Name of the file to manage
    ///   - fileManager: File manager for filesystem operations
    ///   - dataManager: Data manager for I/O operations
    ///   - directoryProvider: Provider for application directories
    ///   - errorMapper: Function to map directory errors to appropriate types
    public init(
        fileName: String,
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider(),
        errorMapper: @escaping @Sendable () -> Error = {
            OutfitPickerError.invalidConfiguration
        }
    ) {
        self.fileName = fileName
        self.fileManager = fileManager
        self.dataManager = dataManager
        self.directoryProvider = directoryProvider
        self.errorMapper = errorMapper
    }

    public func filePath() throws -> URL {
        do {
            return try directoryProvider.baseDirectory()
                .appending(path: appName, directoryHint: .isDirectory)
                .appending(path: fileName, directoryHint: .notDirectory)
        } catch {
            throw errorMapper()
        }
    }

    public func load() throws -> T? {
        let url = try filePath()
        guard
            fileManager.fileExists(
                atPath: url.path(percentEncoded: false),
                isDirectory: nil
            )
        else {
            return nil
        }
        let data = try dataManager.data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save(_ object: T) throws {
        let url = try filePath()
        try ensureDirectoryExists(at: url.deletingLastPathComponent())

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(object)
        try dataManager.write(data, to: url)
    }

    public func delete() throws {
        let url = try filePath()
        if fileManager.fileExists(
            atPath: url.path(percentEncoded: false),
            isDirectory: nil
        ) {
            try fileManager.removeItem(at: url)
        }
    }

    private func ensureDirectoryExists(at url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
