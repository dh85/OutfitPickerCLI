import Testing
import Foundation
@testable import OutfitPickerCLI
@testable import OutfitPickerCore

@Suite("Configuration Tests")
struct ConfigurationTests {
    
    @Test("Configuration stores values correctly")
    func configurationStoresValues() {
        let config = Configuration(
            outfitPath: "/test/outfits",
            language: "en",
            excludedCategories: ["old", "damaged"]
        )
        
        #expect(config.outfitPath == "/test/outfits")
        #expect(config.language == "en")
        #expect(config.excludedCategories == ["old", "damaged"])
    }
    
    @Test("Configuration with empty excluded categories")
    func configurationWithEmptyExcludedCategories() {
        let config = Configuration(
            outfitPath: "/test/outfits",
            language: "es",
            excludedCategories: []
        )
        
        #expect(config.outfitPath == "/test/outfits")
        #expect(config.language == "es")
        #expect(config.excludedCategories.isEmpty)
    }
    
    @Test("createOutfitPicker uses default language when invalid")
    func createOutfitPickerUsesDefaultLanguage() async throws {
        let config = Configuration(
            outfitPath: "/test/outfits",
            language: "invalid",
            excludedCategories: []
        )
        
        do {
            _ = try await config.createOutfitPicker()
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
    
    @Test("createOutfitPicker with valid language")
    func createOutfitPickerWithValidLanguage() async throws {
        let config = Configuration(
            outfitPath: "/test/outfits",
            language: "es",
            excludedCategories: ["old"]
        )
        
        do {
            _ = try await config.createOutfitPicker()
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
    
    @Test("createOutfitPicker with multiple excluded categories")
    func createOutfitPickerWithMultipleExcludedCategories() async throws {
        let config = Configuration(
            outfitPath: "/test/outfits",
            language: "en",
            excludedCategories: ["old", "damaged", "too-small"]
        )
        
        do {
            _ = try await config.createOutfitPicker()
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
