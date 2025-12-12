import Testing
import Foundation
@testable import OutfitPickerCore

@Suite("ErrorMapper Tests")
struct ErrorMapperTests {
    
    @Test("mapError passes through OutfitPickerError")
    func mapErrorPassthrough() {
        let error = OutfitPickerError.categoryNotFound
        let result = ErrorMapper.mapError(error)
        
        #expect(result == .categoryNotFound)
    }
    
    @Test("mapError converts ConfigError to invalidConfiguration")
    func mapErrorConfigError() {
        let error = ConfigError.missingRoot
        let result = ErrorMapper.mapError(error)
        
        #expect(result == .invalidConfiguration)
    }
    
    @Test("mapError converts CacheError to cacheError")
    func mapErrorCacheError() {
        let error = CacheError.encodingFailed
        let result = ErrorMapper.mapError(error)
        
        #expect(result == .cacheError)
    }
    
    @Test("mapError converts FileSystemError to fileSystemError")
    func mapErrorFileSystemError() {
        let error = FileSystemError.permissionDenied
        let result = ErrorMapper.mapError(error)
        
        #expect(result == .fileSystemError)
    }
    
    @Test("execute async rethrows mapped error")
    func executeAsyncThrows() async {
        await #expect(throws: OutfitPickerError.self) {
            try await ErrorMapper.execute {
                throw ConfigError.missingRoot
            }
        }
    }
    
    @Test("execute async returns success value")
    func executeAsyncSuccess() async throws {
        let result = try await ErrorMapper.execute {
            return 42
        }
        
        #expect(result == 42)
    }
    
    @Test("execute sync rethrows mapped error")
    func executeSyncThrows() {
        #expect(throws: OutfitPickerError.self) {
            try ErrorMapper.execute {
                throw FileSystemError.permissionDenied
            }
        }
    }
    
    @Test("execute sync returns success value")
    func executeSyncSuccess() throws {
        let result = try ErrorMapper.execute {
            return "success"
        }
        
        #expect(result == "success")
    }
}
