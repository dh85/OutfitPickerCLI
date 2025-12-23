import Foundation

public protocol ConfigServiceProtocol: Sendable {
    func load() throws -> Config
    func save(_ config: Config) throws
    func delete() throws
    func configPath() throws -> URL
}
