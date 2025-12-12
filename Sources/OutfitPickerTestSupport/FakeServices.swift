import Foundation
import OutfitPickerCore

/// Fake service implementations for OutfitPicker testing.
///
/// This module provides fake implementations of core protocols that enable
/// controlled testing of various scenarios including error conditions.

// MARK: - Fake Service Implementations

/// Fake implementation of ConfigServiceProtocol for testing.
///
/// Provides controllable behavior for configuration loading, allowing tests
/// to simulate both successful operations and error conditions.
///
/// ## Usage Example
/// ```swift
/// // Success case
/// let config = try Config(root: "/test", language: "en")
/// let service = FakeConfigService(.ok(config))
///
/// // Error case
/// let service = FakeConfigService(.throwsError(ConfigError.missingRoot))
/// ```
public final class FakeConfigService: ConfigServiceProtocol, @unchecked Sendable {
    /// Defines the behavior mode for the fake service.
    public enum Mode {
        /// Returns the provided configuration successfully
        case ok(Config)
        /// Throws the provided error when load() is called
        case throwsError(Error)
    }

    /// The configured behavior mode
    public let mode: Mode

    /// Initializes the fake service with the specified behavior mode.
    ///
    /// - Parameter mode: The behavior mode to use
    public init(_ mode: Mode) { self.mode = mode }

    /// Loads configuration according to the configured mode.
    ///
    /// - Returns: The configured Config object
    /// - Throws: The configured error if in throwsError mode
    public func load() throws -> Config {
        switch mode {
        case .ok(let c): return c
        case .throwsError(let e): throw e
        }
    }

    /// Not implemented - will cause fatal error if called.
    ///
    /// - Parameter config: Unused parameter
    /// - Throws: Never throws (fatal error instead)
    public func save(_ config: Config) throws { fatalError("not used") }

    /// Not implemented - will cause fatal error if called.
    ///
    /// - Throws: Never throws (fatal error instead)
    public func delete() throws { fatalError("not used") }

    /// Not implemented - will cause fatal error if called.
    ///
    /// - Returns: Never returns (fatal error instead)
    /// - Throws: Never throws (fatal error instead)
    public func configPath() throws -> URL { fatalError("not used") }

}

/// Fake implementation of CacheServiceProtocol for testing.
///
/// Provides controllable behavior for cache operations and tracks save operations
/// for verification in tests.
///
/// ## Usage Example
/// ```swift
/// // Success case
/// let cache = OutfitCache()
/// let service = FakeCacheService(.ok(cache))
///
/// // Error case
/// let service = FakeCacheService(.throwsOnLoad(CacheError.corruptData))
///
/// // Verify saves
/// try service.save(updatedCache)
/// XCTAssertEqual(service.saved.count, 1)
/// ```
public final class FakeCacheService: CacheServiceProtocol, @unchecked Sendable {
    /// Defines the behavior mode for the fake service.
    public enum Mode {
        /// Returns the provided cache successfully
        case ok(OutfitCache)
        /// Throws the provided error when load() is called
        case throwsOnLoad(Error)
    }

    /// The configured behavior mode
    public let mode: Mode

    /// Initializes the fake service with the specified behavior mode.
    ///
    /// - Parameter mode: The behavior mode to use
    public init(_ mode: Mode) { self.mode = mode }

    /// Array of all cache objects that have been saved.
    ///
    /// Used by tests to verify that save operations occurred with expected data.
    public private(set) var saved: [OutfitCache] = []

    /// Loads cache according to the configured mode.
    ///
    /// - Returns: The last saved cache if any, otherwise the configured OutfitCache object
    /// - Throws: The configured error if in throwsOnLoad mode
    public func load() throws -> OutfitCache {
        switch mode {
        case .ok(let c): return saved.last ?? c
        case .throwsOnLoad(let e): throw e
        }
    }

    /// Saves the cache object to the saved array for test verification.
    ///
    /// - Parameter cache: The cache object to save
    /// - Throws: Never throws in this fake implementation
    public func save(_ cache: OutfitCache) throws { saved.append(cache) }

    /// Not implemented - will cause fatal error if called.
    ///
    /// - Throws: Never throws (fatal error instead)
    public func delete() throws { fatalError("not used") }

    /// Not implemented - will cause fatal error if called.
    ///
    /// - Returns: Never returns (fatal error instead)
    /// - Throws: Never throws (fatal error instead)
    public func cachePath() throws -> URL { fatalError("not used") }
}

/// Fake implementation of FileManagerProtocol for testing.
///
/// Provides controllable filesystem behavior including directory contents,
/// error simulation, and special behaviors like files disappearing between calls.
///
/// ## Usage Example
/// ```swift
/// // Success case with filesystem structure
/// let contents = [rootURL: [categoryURL]]
/// let fm = FakeFileManager(.ok(contents), directories: [rootURL])
///
/// // Error case
/// let fm = FakeFileManager(.throwsError(FileSystemError.accessDenied))
///
/// // Simulate files disappearing
/// let fm = FakeFileManager(.ok(contents), secondCallEmptyFor: [categoryURL])
/// ```
public final class FakeFileManager: FileManagerProtocol, @unchecked Sendable {
    /// Defines the behavior mode for filesystem operations.
    public enum Behavior {
        /// Returns the provided filesystem structure successfully
        case ok([URL: [URL]])
        /// Throws the provided error for filesystem operations
        case throwsError(Error)
    }

    /// The configured behavior mode
    public let behavior: Behavior

    /// Set of directory paths that should be reported as directories
    public let directories: Set<String>

    /// Directory paths where the second call to contentsOfDirectory returns empty.
    ///
    /// Used to simulate files disappearing between filesystem operations,
    /// which can happen in real-world scenarios.
    public let secondCallEmptyFor: Set<String>

    /// Tracks the number of calls to contentsOfDirectory for each path
    private var callCounts: [String: Int] = [:]

    /// Initializes the fake file manager with specified behavior.
    ///
    /// - Parameters:
    ///   - behavior: The filesystem behavior to simulate
    ///   - directories: URLs that should be treated as directories
    ///   - secondCallEmptyFor: URLs that should return empty on second call
    public init(
        _ behavior: Behavior,
        directories: [URL] = [],
        secondCallEmptyFor: [URL] = []
    ) {
        self.behavior = behavior
        self.directories = Set(
            directories.map { $0.path(percentEncoded: false) }
        )
        self.secondCallEmptyFor = Set(
            secondCallEmptyFor.map { $0.path(percentEncoded: false) }
        )
    }

    /// Returns directory contents according to configured behavior.
    ///
    /// - Parameters:
    ///   - url: The directory URL to list
    ///   - keys: Resource keys (ignored in fake implementation)
    ///   - mask: Enumeration options (ignored in fake implementation)
    /// - Returns: Array of URLs representing directory contents
    /// - Throws: Configured error if in throwsError mode
    public func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        switch behavior {
        case .throwsError(let e):
            throw e
        case .ok(let map):
            let path = url.path(percentEncoded: false)

            let count = (callCounts[path] ?? 0) + 1
            callCounts[path] = count

            // If configured, return real contents on first call, empty on 2nd+
            if secondCallEmptyFor.contains(path), count >= 2 {
                return []
            }

            return map[url] ?? []
        }
    }

    /// Checks if a file exists and whether it's a directory.
    ///
    /// - Parameters:
    ///   - path: The file path to check
    ///   - isDirectory: Pointer to receive directory status
    /// - Returns: Always returns true in this fake implementation
    public func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool {
        if let ptr = isDirectory {
            ptr.pointee = ObjCBool(directories.contains(path))
        }
        return true
    }

    /// Returns URLs for search path directories.
    ///
    /// - Parameters:
    ///   - directory: The search path directory type
    ///   - domainMask: The domain mask
    /// - Returns: Empty array in this fake implementation
    public func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] { [] }

    /// Creates a directory (no-op in fake implementation).
    ///
    /// - Parameters:
    ///   - url: Directory URL to create
    ///   - createIntermediates: Whether to create intermediate directories
    ///   - attributes: Directory attributes
    /// - Throws: Never throws in this fake implementation
    public func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {}

    /// Removes an item (no-op in fake implementation).
    ///
    /// - Parameter url: URL of item to remove
    /// - Throws: Never throws in this fake implementation
    public func removeItem(at url: URL) throws {}
}
