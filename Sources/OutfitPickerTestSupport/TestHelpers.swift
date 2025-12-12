import Foundation

/// Test helper utilities for OutfitPicker testing.
///
/// This module provides utility functions that simplify common testing operations
/// such as temporary directory management and file existence checking.
/// These helpers are designed to make tests more readable and maintainable.

// MARK: - Temporary Directory Helpers

/// Creates a unique temporary directory URL for isolated test runs.
///
/// This function generates a unique URL within the system's temporary directory
/// using a UUID to ensure test isolation. The directory itself is not created
/// automatically - tests must create it if needed.
///
/// - Returns: A unique URL for a temporary directory
///
/// ## Usage Example
/// ```swift
/// let tempDir = uniqueTempDir()
/// try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
///
/// // Use tempDir for test files
/// let configURL = tempDir.appending(path: "config.json")
///
/// // Cleanup after test
/// try? FileManager.default.removeItem(at: tempDir)
/// ```
///
/// ## Thread Safety
/// This function is thread-safe as it uses UUID generation which is thread-safe.
/// Each call returns a unique directory path, preventing conflicts between
/// concurrent test runs.
public func uniqueTempDir() -> URL {
    FileManager.default.temporaryDirectory
        .appending(
            path: "outfitpicker-tests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
}

// MARK: - File System Helpers

/// Checks if a file or directory exists at the specified URL.
///
/// This is a convenience wrapper around FileManager.fileExists(atPath:)
/// that works directly with URL objects and handles path encoding automatically.
///
/// - Parameter url: The URL to check for existence
/// - Returns: `true` if a file or directory exists at the URL, `false` otherwise
///
/// ## Usage Example
/// ```swift
/// let configURL = tempDir.appending(path: "config.json")
///
/// if fileExists(configURL) {
///     // File exists, can read it
///     let data = try Data(contentsOf: configURL)
/// } else {
///     // File doesn't exist, create default
///     try defaultConfig.write(to: configURL)
/// }
/// ```
///
/// ## Notes
/// - The `@discardableResult` attribute allows the return value to be ignored
///   when used for side effects or assertions
/// - This function does not distinguish between files and directories
/// - Path encoding is handled automatically using `percentEncoded: false`
@discardableResult
public func fileExists(_ url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
}

// MARK: - Path Helpers

/// Creates a temporary directory, executes the closure, and cleans up automatically.
///
/// - Parameter body: Closure that receives the temporary directory URL
/// - Returns: The result of the closure
/// - Throws: Any error thrown by the closure
///
/// ## Usage Example
/// ```swift
/// try withTempDir { tempDir in
///     let sut = ConfigService(directoryProvider: FixedDirectoryProvider(url: tempDir))
///     try sut.save(config)
/// } // Automatic cleanup
/// ```
public func withTempDir<T>(_ body: (URL) throws -> T) rethrows -> T {
    let dir = uniqueTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    return try body(dir)
}

/// Normalizes a path by removing trailing slashes.
///
/// - Parameter p: The path string to normalize
/// - Returns: The normalized path without trailing slash
///
/// ## Usage Example
/// ```swift
/// let normalized = normPath("/path/to/dir/")  // Returns "/path/to/dir"
/// let unchanged = normPath("/path/to/file")   // Returns "/path/to/file"
/// ```
public func normPath(_ p: String) -> String {
    p.hasSuffix("/") ? String(p.dropLast()) : p
}
