import Foundation
import OutfitPickerCore

struct CategoryMenu {
    let outfitService: OutfitService
    let presentation: OutfitPresentation
    let category: CategoryReference

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
        while true {
            do {
                guard
                    let outfit = try await outfitService.picker.showNextUniqueRandomOutfit(
                        from: category.name)
                else {
                    UI.info("No outfits available in \(category.name)")
                    await MainMenu(outfitService: outfitService, presentation: presentation).show()
                    return
                }

                let result = await presentation.presentOutfitWithChoice(outfit)

                switch result {
                case .worn:
                    // Session is reset in Core's wearOutfit method
                    await MainMenu(outfitService: outfitService, presentation: presentation).show()
                    return
                case .skipped:
                    // Continue to next iteration - Core tracks the shown outfit
                    continue
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
