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
            let statusText = "\(state.wornCount) of \(state.totalCount) outfits worn"
            print(
                "\n📁 \(UI.colorize(category.name, UI.bold + UI.blue)) \(UI.colorize("(\(statusText))", UI.yellow))"
            )

            print("  \(UI.colorize("[P]", UI.bold + UI.green)) Pick random outfit (default)")
            print("  \(UI.colorize("[R]", UI.bold + UI.green)) Reset category")
            print("  \(UI.colorize("[B]", UI.bold + UI.green)) Back")

            let input = UI.prompt("Choose an option: ")?.lowercased() ?? ""

            switch input {
            case "r":
                try await outfitService.picker.resetCategory(category.name)
                UI.success("Reset worn outfits for \(category.name)")
                await show()
            case "b":
                await MainMenu(outfitService: outfitService, presentation: presentation).show()
            case "p", "":
                await handleOutfitLoop()
            default:
                await show()
            }
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
