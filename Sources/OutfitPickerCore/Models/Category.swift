import Foundation

/// Internal model representing a category of outfit files organized in a directory.
struct Category: Sendable, Equatable {
    let path: String
    let outfits: [String]
    private let _url: URL

    init(path: String, outfits: [String]) {
        self.path = path
        self.outfits = outfits
        self._url = URL(filePath: path, directoryHint: .isDirectory)
    }

    var name: String {
        _url.lastPathComponent
    }
}

/// Internal model representing an individual outfit file with its context information.
struct FileEntry: Equatable, Sendable {
    let filePath: String
    let fileName: String
    private let _url: URL
    private let _categoryURL: URL

    init(filePath: String) {
        self.filePath = filePath
        self._url = URL(filePath: filePath, directoryHint: .notDirectory)
        self.fileName = _url.lastPathComponent
        self._categoryURL = _url.deletingLastPathComponent()
    }

    var categoryPath: String {
        _categoryURL.path(percentEncoded: false)
    }

    var categoryName: String {
        _categoryURL.lastPathComponent
    }
}
