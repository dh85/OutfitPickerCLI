import Testing
@testable import OutfitPickerCLI

struct OutfitPresentationTests {
    
    @Test func outfitChoiceEnum() {
        let choices: [OutfitChoice] = [.worn, .skipped, .quit]
        #expect(choices.count == 3)
    }
    
    @Test func outfitChoiceEquality() {
        #expect(OutfitChoice.worn == OutfitChoice.worn)
        #expect(OutfitChoice.skipped == OutfitChoice.skipped)
        #expect(OutfitChoice.quit == OutfitChoice.quit)
        #expect(OutfitChoice.worn != OutfitChoice.skipped)
    }
}