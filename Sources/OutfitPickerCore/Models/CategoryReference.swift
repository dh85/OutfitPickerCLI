import Foundation

/// Reference to a category directory containing outfit files.
///
/// CategoryReference provides a lightweight way to identify and reference
/// a category without loading all its outfit files.
public struct CategoryReference: Sendable, Hashable, CustomStringConvertible {
    /// Display name of the category
    public let name: String
    /// Full filesystem path to the category directory
    public let path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }

    public var description: String { name }
}
