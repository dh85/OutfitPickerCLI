import Foundation

/// Internal model representing an individual outfit file with its context information.
public struct FileEntry: Equatable, Sendable {
    let filePath: String
    public let fileName: String
    private let _url: URL
    private let _categoryURL: URL

    public init(filePath: String) {
        self.filePath = filePath
        self._url = URL(filePath: filePath, directoryHint: .notDirectory)
        self.fileName = _url.lastPathComponent
        self._categoryURL = _url.deletingLastPathComponent()
    }

    public var categoryPath: String {
        _categoryURL.path(percentEncoded: false)
    }

    public var categoryName: String {
        _categoryURL.lastPathComponent
    }
}
