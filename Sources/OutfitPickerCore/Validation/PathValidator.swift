import Foundation

struct PathValidator {
    private static let maxPathLength = 4096
    private static let restrictedPaths: Set<String> = {
        #if os(Windows)
            return [
                "C:\\Windows\\System32", "C:\\Program Files",
                "C:\\Users\\Administrator", "\\\\localhost\\C$",
            ]
        #else
            return [
                "/etc", "/usr", "/bin", "/sbin", "/System", "/private", "/var",
                "/tmp", "/root",
            ]
        #endif
    }()

    static func validate(_ path: String) throws {
        // Check for invalid characters
        try validateCharacters(path)

        // Check path length
        try validateLength(path)

        // Check for path traversal attempts
        try validateTraversal(path)

        // Check against restricted paths
        try validateRestrictedPaths(path)

        // Check for symlink traversal
        try validateSymlinks(path)
    }

    private static func validateCharacters(_ path: String) throws {
        let sanitized = sanitizePath(path)
        if sanitized != path {
            throw ConfigError.invalidCharacters
        }
    }

    private static func validateLength(_ path: String) throws {
        guard path.count <= maxPathLength else {
            throw ConfigError.pathTooLong
        }
    }

    private static func validateTraversal(_ path: String) throws {
        if path.contains("..") {
            throw ConfigError.pathTraversalNotAllowed
        }

        let url = URL(filePath: path, directoryHint: .isDirectory)
        let standardized = url.standardized

        let originalComponents = path.components(separatedBy: "/")
        let standardizedComponents = standardized.path.components(
            separatedBy: "/"
        )

        if originalComponents.count > standardizedComponents.count + 2 {
            throw ConfigError.pathTraversalNotAllowed
        }
    }

    private static func validateRestrictedPaths(_ path: String) throws {
        let normalizedPath = path.lowercased()
        for restricted in restrictedPaths {
            if normalizedPath.hasPrefix(restricted.lowercased()) {
                throw ConfigError.restrictedPath
            }
        }
    }

    private static func validateSymlinks(_ path: String) throws {
        if ProcessInfo.processInfo.environment[
            "OUTFITPICKER_DISABLE_SYMLINK_CHECK"
        ] == "true" {
            return
        }
        let url = URL(filePath: path, directoryHint: .isDirectory)
        let standardized = url.standardized
        let resolved = url.resolvingSymlinksInPath()

        if resolved.path(percentEncoded: false)
            != standardized.path(percentEncoded: false)
        {
            throw ConfigError.symlinkNotAllowed
        }
    }

    private static func sanitizePath(_ path: String) -> String {
        return path.filter { char in
            let ascii = char.asciiValue ?? 0
            return ascii >= 32 && ascii <= 126
        }
    }

    static var maximumPathLength: Int {
        return maxPathLength
    }

    static var platformRestrictedPaths: Set<String> {
        return restrictedPaths
    }
}
