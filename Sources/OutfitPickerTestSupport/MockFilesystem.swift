import Foundation
import OutfitPickerCore

/// Mock filesystem utilities for OutfitPicker testing.
///
/// This module provides functions to create mock filesystem structures
/// that can be used with fake file managers for isolated testing.

// MARK: - Filesystem Structure Creation

/// Creates a mock filesystem structure for a single category.
///
/// - Parameters:
///   - root: The root directory path
///   - name: The category name (subdirectory)
///   - files: Array of file names to create in the category
/// - Returns: A tuple containing the category directory URL and filesystem mapping
///
/// ## Usage Example
/// ```swift
/// let (dir, map) = makeCategoryDir(
///     root: "/test/outfits",
///     name: "casual",
///     files: ["shirt1.avatar", "pants1.avatar"]
/// )
/// ```
public func makeCategoryDir(
    root: String,
    name: String,
    files: [String]
) -> (dir: URL, map: [URL: [URL]]) {
    let dir = URL(filePath: root, directoryHint: .isDirectory)
        .appending(path: name, directoryHint: .isDirectory)
    let urls = files.map {
        dir.appending(path: $0, directoryHint: .notDirectory)
    }
    return (dir, [dir: urls])
}

/// Creates a complete mock filesystem structure with multiple categories.
///
/// - Parameters:
///   - root: The root directory path
///   - categories: Dictionary mapping category names to their file lists
/// - Returns: A tuple containing root URL, filesystem contents mapping, and directory set
///
/// ## Usage Example
/// ```swift
/// let fs = makeFS(
///     root: "/test/outfits",
///     categories: [
///         "casual": ["shirt1.avatar", "pants1.avatar"],
///         "formal": ["suit1.avatar", "tie1.avatar"]
///     ]
/// )
/// ```
public func makeFS(
    root: String,
    categories: [String: [String]]
) -> (rootURL: URL, contents: [URL: [URL]], directories: Set<URL>) {
    let rootURL = URL(filePath: root, directoryHint: .isDirectory)
    var map: [URL: [URL]] = [:]
    var dirs: Set<URL> = [rootURL]

    let categoryDirs = categories.keys.sorted().map {
        rootURL.appending(path: $0, directoryHint: .isDirectory)
    }
    map[rootURL] = categoryDirs
    dirs.formUnion(categoryDirs)

    for (name, files) in categories {
        let d = rootURL.appending(path: name, directoryHint: .isDirectory)
        map[d] = files.map {
            d.appending(path: $0, directoryHint: .notDirectory)
        }
    }

    return (rootURL, map, dirs)
}
