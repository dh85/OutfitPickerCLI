import Foundation

public protocol CacheServiceProtocol: Sendable {
    func load() throws -> OutfitCache
    func save(_ cache: OutfitCache) throws
    func delete() throws
    func cachePath() throws -> URL
}
