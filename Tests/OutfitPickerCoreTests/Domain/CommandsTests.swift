import Testing
import Foundation
@testable import OutfitPickerCore

@Suite("Commands Tests")
struct CommandsTests {
    
    @Test("WearOutfitCommand stores outfit reference")
    func wearOutfitCommand() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let outfit = OutfitReference(fileName: "shirt.avatar", category: category)
        let command = WearOutfitCommand(outfit: outfit)
        
        #expect(command.outfit == outfit)
        #expect(command.outfit.fileName == "shirt.avatar")
        #expect(command.outfit.category.name == "casual")
    }
    
    @Test("ResetCategoryCommand stores category name")
    func resetCategoryCommand() {
        let command = ResetCategoryCommand(categoryName: "casual")
        
        #expect(command.categoryName == "casual")
    }
    
    @Test("ResetAllCategoriesCommand initializes")
    func resetAllCategoriesCommand() {
        let command = ResetAllCategoriesCommand()
        
        #expect(command != nil)
    }
}
