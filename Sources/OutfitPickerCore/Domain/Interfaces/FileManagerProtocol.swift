import Foundation

public protocol FileManagerProtocol: Sendable {
    func contentsOfDirectory(
        at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL]
    func createDirectory(
        at url: URL, withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?) throws
    func removeItem(at URL: URL) throws
}

extension FileManager: FileManagerProtocol {}
