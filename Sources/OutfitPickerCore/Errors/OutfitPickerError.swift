import Foundation

enum ConfigError: LocalizedError, Equatable {
    case emptyRoot
    case missingRoot
    case missingLanguage
    case unsupportedLanguage(String)
    case pathTraversalNotAllowed
    case pathTooLong
    case restrictedPath
    case symlinkNotAllowed
    case invalidCharacters

    public var errorDescription: String? {
        switch self {
        case .emptyRoot: "empty root in configuration"
        case .missingRoot: "missing root in configuration"
        case .missingLanguage: "missing language in configuration"
        case .unsupportedLanguage(let lang): "unsupported language: \(lang)"
        case .pathTraversalNotAllowed: "path traversal not allowed"
        case .pathTooLong: "path too long"
        case .restrictedPath: "restricted path"
        case .symlinkNotAllowed: "symlink not allowed"
        case .invalidCharacters: "invalid characters"
        }
    }
}

enum FileSystemError: LocalizedError, Equatable {
    case fileNotFound
    case directoryNotFound
    case permissionDenied
    case invalidPath
    case operationFailed

    public var errorDescription: String? {
        switch self {
        case .fileNotFound: "file not found"
        case .directoryNotFound: "directory not found"
        case .permissionDenied: "permission denied"
        case .invalidPath: "invalid path"
        case .operationFailed: "operation failed"
        }
    }
}

enum CacheError: LocalizedError, Equatable {
    case encodingFailed
    case decodingFailed
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .encodingFailed: "failed to encode cache data"
        case .decodingFailed: "failed to decode cache data"
        case .invalidData: "invalid cache data"
        }
    }
}

enum StorageError: LocalizedError, Equatable {
    case diskFull
    case corruptedData

    public var errorDescription: String? {
        switch self {
        case .diskFull: "disk full"
        case .corruptedData: "data corrupted"
        }
    }
}
