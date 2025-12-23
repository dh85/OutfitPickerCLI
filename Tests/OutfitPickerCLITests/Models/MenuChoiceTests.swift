import Testing

@testable import OutfitPickerCLI

struct MenuChoiceTests {

    @Test func menuChoiceDescriptions() {
        #expect(MenuChoice.random.description == "🎲 Pick a random outfit")
        #expect(MenuChoice.worn.description == "✅ Show outfits I've already worn")
        #expect(MenuChoice.unworn.description == "📄 Show outfits I haven't worn yet")
        #expect(MenuChoice.advanced.description == "🔧 Advanced settings")
        #expect(MenuChoice.quit.description == "👋 Exit")
    }

    @Test func advancedChoiceDescriptions() {
        #expect(AdvancedChoice.changePath.description == "Change outfit path")
        #expect(AdvancedChoice.changeLanguage.description == "Change language")
        #expect(
            AdvancedChoice.changeExcluded.description
                == "Manage categories excluded from random selection")
        #expect(AdvancedChoice.resetCategory.description == "Reset worn outfits for category")
        #expect(AdvancedChoice.resetAll.description == "Reset all worn outfits")
        #expect(AdvancedChoice.resetSettings.description == "Reset user settings and worn outfits")
        #expect(AdvancedChoice.back.description == "Back to main menu")
        #expect(AdvancedChoice.quit.description == "Quit")
    }

    @Test func menuChoiceRawValues() {
        #expect(MenuChoice.random.rawValue == "r")
        #expect(MenuChoice.worn.rawValue == "w")
        #expect(MenuChoice.unworn.rawValue == "u")
        #expect(MenuChoice.advanced.rawValue == "a")
        #expect(MenuChoice.quit.rawValue == "q")
    }

    @Test func advancedChoiceRawValues() {
        #expect(AdvancedChoice.changePath.rawValue == "p")
        #expect(AdvancedChoice.changeLanguage.rawValue == "l")
        #expect(AdvancedChoice.changeExcluded.rawValue == "e")
        #expect(AdvancedChoice.resetCategory.rawValue == "c")
        #expect(AdvancedChoice.resetAll.rawValue == "r")
        #expect(AdvancedChoice.resetSettings.rawValue == "s")
        #expect(AdvancedChoice.back.rawValue == "b")
        #expect(AdvancedChoice.quit.rawValue == "q")
    }

    @Test func menuChoiceInitFromRawValue() {
        #expect(MenuChoice(rawValue: "r") == .random)
        #expect(MenuChoice(rawValue: "w") == .worn)
        #expect(MenuChoice(rawValue: "invalid") == nil)
    }

    @Test func advancedChoiceInitFromRawValue() {
        #expect(AdvancedChoice(rawValue: "p") == .changePath)
        #expect(AdvancedChoice(rawValue: "q") == .quit)
        #expect(AdvancedChoice(rawValue: "invalid") == nil)
    }

    @Test func menuChoiceAllCases() {
        #expect(MenuChoice.allCases.count == 6)
        #expect(MenuChoice.allCases.contains(.random))
        #expect(MenuChoice.allCases.contains(.manual))
        #expect(MenuChoice.allCases.contains(.quit))
    }

    @Test func advancedChoiceAllCases() {
        #expect(AdvancedChoice.allCases.count == 8)
        #expect(AdvancedChoice.allCases.contains(.changePath))
        #expect(AdvancedChoice.allCases.contains(.quit))
    }
}
