import Foundation
import OutfitPickerCore

struct MenuSystem {
    let picker: OutfitPicker

    init(picker: OutfitPicker) {
        self.picker = picker
    }

    func showMainMenu() async {
        let outfitService = OutfitService(picker: picker)
        let presentation = OutfitPresentation(picker: picker)
        await MainMenu(outfitService: outfitService, presentation: presentation).show()
    }
}
