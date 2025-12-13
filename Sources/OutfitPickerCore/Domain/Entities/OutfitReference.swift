import Foundation

/// Reference to a specific outfit file within a category.
///
/// OutfitReference combines a filename with its category context,
/// providing complete information needed to locate and display an outfit.
public struct OutfitReference: Sendable, Hashable, CustomStringConvertible {
    /// Name of the outfit file
    public let fileName: String
    /// Category containing this outfit
    public let category: CategoryReference

    public init(fileName: String, category: CategoryReference) {
        self.fileName = fileName
        self.category = category
    }

    /// Complete filesystem path to the outfit file
    public var filePath: String {
        URL(filePath: category.path, directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)
            .path(percentEncoded: false)
    }

    public var description: String { "\(fileName) in \(category.name)" }
}
