import Foundation
import OutfitPickerCore

/// Test doubles for OutfitPicker testing.
///
/// This module provides specialized test double implementations for various protocols
/// used throughout the OutfitPicker system. These test doubles enable controlled
/// testing of error conditions, behavior verification, and edge cases.
///
/// ## Key Components
/// - **Directory Providers**: Test doubles for directory resolution
/// - **Data Managers**: Test doubles for data I/O operations
/// - **File Managers**: Specialized file manager implementations for testing

// MARK: - Directory Provider Test Doubles

/// Directory provider that always returns a fixed URL.
///
/// Used for testing scenarios where you need predictable directory resolution
/// without relying on the actual filesystem or environment variables.
///
/// ## Usage Example
/// ```swift
/// let provider = FixedDirectoryProvider(url: URL(filePath: "/test/config"))
/// let service = ConfigService(directoryProvider: provider)
/// // Service will always use /test/config as base directory
/// ```
public struct FixedDirectoryProvider: DirectoryProvider {
    /// The fixed URL to return from baseDirectory()
    public let url: URL

    /// Initializes with a fixed URL.
    ///
    /// - Parameter url: The URL to always return from baseDirectory()
    public init(url: URL) { self.url = url }

    /// Returns the fixed URL.
    ///
    /// - Returns: The URL provided during initialization
    /// - Throws: Never throws
    public func baseDirectory() throws -> URL { url }
}

/// Directory provider that always throws an error.
///
/// Used for testing error handling when directory resolution fails,
/// such as when XDG_CONFIG_HOME is invalid or Application Support is unavailable.
///
/// ## Usage Example
/// ```swift
/// let provider = ThrowingDirectoryProvider(StorageError.directoryUnavailable)
/// let service = ConfigService(directoryProvider: provider)
/// // Service operations will fail with the specified error
/// ```
public struct ThrowingDirectoryProvider: DirectoryProvider {
    /// The error to throw from baseDirectory()
    public let error: Error

    /// Initializes with a specific error to throw.
    ///
    /// - Parameter error: The error to throw (defaults to generic NSError)
    public init(_ error: Error = NSError(domain: "dir", code: 1, userInfo: nil)) {
        self.error = error
    }

    /// Always throws the configured error.
    ///
    /// - Returns: Never returns
    /// - Throws: The error provided during initialization
    public func baseDirectory() throws -> URL { throw error }
}

// MARK: - Data Manager Test Doubles

/// Data manager that throws errors on write operations.
///
/// Used for testing error handling when file write operations fail,
/// such as due to permission issues or disk space problems.
///
/// ## Usage Example
/// ```swift
/// let dataManager = ThrowingDataManager(StorageError.writeFailed)
/// let service = FileService(dataManager: dataManager)
/// // Write operations will fail with the specified error
/// ```
public struct ThrowingDataManager: DataManagerProtocol, @unchecked Sendable {
    /// The error to throw from write operations
    public let error: Error

    /// Initializes with a specific error to throw on writes.
    ///
    /// - Parameter error: The error to throw (defaults to generic I/O error)
    public init(_ error: Error = NSError(domain: "io", code: 5, userInfo: nil)) {
        self.error = error
    }

    /// Returns empty data (read operations succeed).
    ///
    /// - Parameter url: The URL to read from (ignored)
    /// - Returns: Empty Data object
    /// - Throws: Never throws
    public func data(contentsOf url: URL) throws -> Data { Data() }

    /// Always throws the configured error.
    ///
    /// - Parameters:
    ///   - data: The data to write (ignored)
    ///   - url: The URL to write to (ignored)
    /// - Throws: The error provided during initialization
    public func write(_ data: Data, to url: URL) throws { throw error }
}

/// Data manager that throws errors on read operations.
///
/// Used for testing error handling when file read operations fail,
/// such as when files don't exist or are inaccessible.
///
/// ## Usage Example
/// ```swift
/// let dataManager = ThrowingReadDataManager(StorageError.fileNotFound)
/// let service = FileService(dataManager: dataManager)
/// // Read operations will fail with the specified error
/// ```
public struct ThrowingReadDataManager: DataManagerProtocol, @unchecked Sendable {
    /// The error to throw from read operations
    public let error: Error

    /// Initializes with a specific error to throw on reads.
    ///
    /// - Parameter error: The error to throw (defaults to generic read error)
    public init(
        _ error: Error = NSError(domain: "io-read", code: 2, userInfo: nil)
    ) {
        self.error = error
    }

    /// Always throws the configured error.
    ///
    /// - Parameter url: The URL to read from (ignored)
    /// - Returns: Never returns
    /// - Throws: The error provided during initialization
    public func data(contentsOf url: URL) throws -> Data { throw error }

    /// Performs normal write operations.
    ///
    /// - Parameters:
    ///   - data: The data to write
    ///   - url: The URL to write to
    /// - Throws: Standard Data.write errors
    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}

/// Data manager that returns corrupted data on read operations.
///
/// Used for testing JSON parsing error handling when files contain
/// invalid or corrupted data.
///
/// ## Usage Example
/// ```swift
/// let dataManager = CorruptingDataManager()
/// let service = ConfigService(fileService: FileService(dataManager: dataManager))
/// // Load operations will fail with JSON parsing errors
/// ```
public struct CorruptingDataManager: DataManagerProtocol, @unchecked Sendable {
    /// Initializes the corrupting data manager.
    public init() {}

    /// Returns invalid JSON data.
    ///
    /// - Parameter url: The URL to read from (ignored)
    /// - Returns: Data containing "not json" which will cause JSON parsing to fail
    /// - Throws: Never throws
    public func data(contentsOf url: URL) throws -> Data {
        Data("not json".utf8)
    }

    /// Performs normal write operations.
    ///
    /// - Parameters:
    ///   - data: The data to write
    ///   - url: The URL to write to
    /// - Throws: Standard Data.write errors
    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}

/// Data manager that records all operations for verification.
///
/// Used for testing that the correct URLs and data are being used
/// in read and write operations. Performs actual I/O while recording.
///
/// ## Usage Example
/// ```swift
/// let dataManager = RecordingDataManager()
/// let service = FileService(dataManager: dataManager)
/// try service.save(data, to: url)
///
/// // Verify the operation
/// XCTAssertEqual(dataManager.lastWriteURL, url)
/// XCTAssertEqual(dataManager.lastData, data)
/// ```
public final class RecordingDataManager: DataManagerProtocol,
    @unchecked Sendable
{
    /// The URL of the last write operation, if any
    public private(set) var lastWriteURL: URL?
    /// The data from the last write operation, if any
    public private(set) var lastData: Data?
    /// The URL of the last read operation, if any
    public private(set) var lastReadURL: URL?

    /// Initializes the recording data manager.
    public init() {}

    /// Reads data and records the URL.
    ///
    /// - Parameter url: The URL to read from
    /// - Returns: The data read from the URL
    /// - Throws: Standard Data(contentsOf:) errors
    public func data(contentsOf url: URL) throws -> Data {
        lastReadURL = url
        return try Data(contentsOf: url)
    }

    /// Writes data and records both URL and data.
    ///
    /// - Parameters:
    ///   - data: The data to write
    ///   - url: The URL to write to
    /// - Throws: Standard Data.write errors
    public func write(_ data: Data, to url: URL) throws {
        lastWriteURL = url
        lastData = data
        try data.write(to: url)
    }
}

// MARK: - File Manager Test Doubles

/// File manager that throws errors on directory creation.
///
/// Used for testing error handling when directory creation fails,
/// such as due to permission issues or filesystem problems.
/// This is specifically designed to test the error path in FileService.save().
///
/// ## Usage Example
/// ```swift
/// let fileManager = FileManagerThrowingCreateDir()
/// let service = FileService(fileManager: fileManager)
/// // Directory creation will fail, testing error handling
/// ```
public final class FileManagerThrowingCreateDir: FileManagerProtocol,
    @unchecked Sendable
{
    /// Initializes the throwing file manager.
    public init() {}

    /// Returns empty directory contents.
    ///
    /// - Parameters:
    ///   - url: The directory URL (ignored)
    ///   - keys: Resource keys (ignored)
    ///   - mask: Enumeration options (ignored)
    /// - Returns: Empty array
    /// - Throws: Never throws
    public func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] { [] }

    /// Always reports files as non-existent.
    ///
    /// - Parameters:
    ///   - path: The file path to check (ignored)
    ///   - isDirectory: Directory status pointer (set to false)
    /// - Returns: Always false
    public func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool {
        if let ptr = isDirectory {
            ptr.pointee = ObjCBool(false)
        }
        return false
    }

    /// Returns a default temporary directory.
    ///
    /// - Parameters:
    ///   - directory: The search path directory (ignored)
    ///   - domainMask: The domain mask (ignored)
    /// - Returns: Array containing /tmp directory URL
    public func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        [URL(filePath: "/tmp", directoryHint: .isDirectory)]
    }

    /// Always throws an error when creating directories.
    ///
    /// This method is designed to force the failure path in FileService.save()
    /// to test error handling when directory creation fails.
    ///
    /// - Parameters:
    ///   - url: The directory URL to create (ignored)
    ///   - createIntermediates: Whether to create intermediate directories (ignored)
    ///   - attributes: Directory attributes (ignored)
    /// - Throws: Always throws an NSError with domain "mkdir" and code 13
    public func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        // Force the failure path in FileService.save(...)
        throw NSError(domain: "mkdir", code: 13, userInfo: nil)
    }

    /// No-op implementation for item removal.
    ///
    /// - Parameter url: The URL of the item to remove (ignored)
    /// - Throws: Never throws
    public func removeItem(at url: URL) throws { /* no-op */  }
}
