import Foundation
import OutfitPickerCore

struct CategoryMenu {
    let outfitService: OutfitService
    let presentation: OutfitPresentation
    let category: CategoryReference
    var session = OutfitSession()

    func show() async {
        do {
            let state = try await outfitService.picker.getOutfitState(for: category)
            print(
                "\n📁 \(UI.colorize(category.name, UI.bold + UI.blue)) \(UI.colorize("(\(state.statusText))", UI.yellow))"
            )

            await handleOutfitLoop()
        } catch {
            UI.error("Error: \(error.localizedDescription)")
        }
    }

    private func handleOutfitLoop() async {
        var session = self.session

        while true {
            do {
                let availableOutfits = try await outfitService.getAvailableOutfits(for: category)
                let unseenOutfits = availableOutfits.filter {
                    !session.isCategorySkipped($0.fileName, category: category.name)
                }

                let outfitsToChooseFrom = unseenOutfits.isEmpty ? availableOutfits : unseenOutfits

                if outfitsToChooseFrom.isEmpty {
                    UI.info("No outfits available in \(category.name)")
                    await MainMenu(outfitService: outfitService, presentation: presentation).show()
                    return
                }

                let outfit = outfitsToChooseFrom.randomElement()!
                let result = await presentation.presentOutfitWithChoice(outfit)

                switch result {
                case .worn:
                    session.resetCategory(category.name)
                    await MainMenu(outfitService: outfitService, presentation: presentation).show()
                    return
                case .skipped:
                    session.addCategorySkipped(outfit.fileName, category: category.name)
                    if unseenOutfits.count <= 1 {
                        session.resetCategory(category.name)
                    }
                case .quit:
                    print("👋 Goodbye!\n")
                    return
                }
            } catch {
                UI.error("Error: \(error.localizedDescription)")
                await MainMenu(outfitService: outfitService, presentation: presentation).show()
                return
            }
        }
    }
}
