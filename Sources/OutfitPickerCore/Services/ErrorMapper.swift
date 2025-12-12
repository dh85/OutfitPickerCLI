import Foundation

public struct ErrorMapper: Sendable {
    public static func mapError(_ error: Error) -> OutfitPickerError {
        if let outfitPickerError = error as? OutfitPickerError {
            return outfitPickerError
        }
        return OutfitPickerError.from(error)
    }

    public static func execute<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw mapError(error)
        }
    }

    public static func execute<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            throw mapError(error)
        }
    }
}
