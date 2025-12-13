import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct ConcurrencyDesignTests {

    @Test func outfitPicker_isActor_properSendable() {
        // OutfitPicker is an actor, so it's inherently Sendable
        // This test verifies we can create it without @unchecked Sendable
        let config = try! Config(root: "/Users/test/outfits")
        let _ = OutfitPicker(config: config)

        // Test passes if no concurrency warnings/errors during compilation
        #expect(Bool(true))
    }

    @Test func categoryScanner_isStruct_properSendable() {
        let scanner = CategoryScanner()

        // Should be able to pass scanner between tasks
        Task {
            let _ = scanner
        }

        // Test passes if no concurrency warnings/errors during compilation
        #expect(Bool(true))
    }

    @Test func services_areProperSendable() {
        let configService = ConfigService()
        let cacheService = CacheService()
        let repository = CategoryRepository(categoryScanner: CategoryScanner())

        // Should be able to pass services between tasks
        Task {
            let _ = configService
            let _ = cacheService
            let _ = repository
        }

        // Test passes if no concurrency warnings/errors during compilation
        #expect(Bool(true))
    }
}
