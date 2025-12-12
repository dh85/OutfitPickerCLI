import Foundation
import Testing

@testable import OutfitPickerCore

struct FileSystemErrorTests {
    @Test
    func errorDescriptions() {
        testErrorDescriptions([
            (FileSystemError.directoryNotFound, "directory not found"),
            (FileSystemError.fileNotFound, "file not found"),
            (FileSystemError.permissionDenied, "permission denied"),
            (FileSystemError.invalidPath, "invalid path"),
            (FileSystemError.operationFailed, "operation failed"),
        ])
    }

    @Test
    func equatableSemantics() {
        testEquatableSemantics(
            equal: [
                (
                    FileSystemError.operationFailed,
                    FileSystemError.operationFailed
                )
            ],
            notEqual: [
                (FileSystemError.operationFailed, FileSystemError.invalidPath)
            ]
        )
    }
}
