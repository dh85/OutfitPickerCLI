import Foundation
import OutfitPickerCore

struct MainMenu {
    let outfitService: OutfitService
    let presentation: OutfitPresentation
    let renderer = MenuRenderer()

    func show() async {
        do {
            renderer.showTitle()
            await showOutfitDirectory()

            let categoryInfos = try await outfitService.picker.getCategoryInfo()
            let availableCategories = try await outfitService.getAvailableCategories()

            if !availableCategories.isEmpty {
                await renderer.showAvailableCategories(
                    availableCategories, picker: outfitService.picker)
            }

            await renderer.showUnavailableCategories(categoryInfos, outfitService: outfitService)
            print("\n")
            renderer.showMenuOptions()

            if let input = UI.prompt("Choose a number or letter: ") {
                await handleChoice(input, availableCategories: availableCategories)
            }
        } catch OutfitPickerError.fileSystemError {
            UI.error("Can't find your outfit folder")
            print("💡 Use Advanced Settings > Change outfit path to fix this")
            await AdvancedMenu(outfitService: outfitService).show()
        } catch {
            UI.error("Error listing categories: \(error.localizedDescription)")
        }
    }

    private func showOutfitDirectory() async {
        do {
            let rootPath = try await outfitService.picker.getRootDirectory()
            let absolutePath = URL(filePath: rootPath).path(percentEncoded: false)
            renderer.showOutfitDirectory(path: absolutePath)
        } catch {
            print("")
        }
    }

    private func handleChoice(_ input: String, availableCategories: [CategoryInfo]) async {
        if let choice = MenuChoice(rawValue: input.lowercased()) {
            switch choice {
            case .random:
                await handleRandomOutfit()
            case .manual:
                await handleManualSelection()
            case .worn:
                await showWornMenu()
            case .unworn:
                await showUnwornMenu()
            case .advanced:
                await AdvancedMenu(outfitService: outfitService).show()
            case .quit:
                print("👋 Goodbye!\n")
                return
            }
        } else if let index = Int(input), index > 0 && index <= availableCategories.count {
            let categoryInfo = availableCategories[index - 1]
            await CategoryMenu(
                outfitService: outfitService, presentation: presentation,
                category: categoryInfo.category
            ).show()
        } else {
            UI.error("Invalid choice")
            await show()
        }
    }

    private func handleRandomOutfit() async {
        while true {
            do {
                guard let randomOutfit = try await outfitService.picker.showNextUniqueRandomOutfit()
                else {
                    UI.info("No outfits available")
                    await show()
                    return
                }

                let result = await presentation.presentOutfitWithCategoryChoice(
                    randomOutfit, category: randomOutfit.category.name)

                switch result {
                case .worn:
                    // Session is reset in Core's wearOutfit method
                    await show()
                    return
                case .quit:
                    print("👋 Goodbye!\n")
                    return
                case .skipped:
                    // Continue to next iteration - Core tracks the shown outfit
                    continue
                }
            } catch {
                UI.error("Error: \(error.localizedDescription)")
                await show()
                return
            }
        }
    }

    private func getAllAvailableOutfits() async throws -> [OutfitReference] {
        let categoryInfos = try await outfitService.picker.getCategoryInfo()
        var allOutfits: [OutfitReference] = []

        for info in categoryInfos {
            if case .hasOutfits = info.state {
                let availableOutfits = try await outfitService.getAvailableOutfits(
                    for: info.category)
                allOutfits.append(contentsOf: availableOutfits)
            }
        }

        return allOutfits
    }

    private func showWornMenu() async {
        do {
            let wornOutfitsByCategory = try await outfitService.getWornOutfits()

            if wornOutfitsByCategory.isEmpty {
                UI.info("No worn outfits found")
                await show()
                return
            }

            renderer.showWornOutfits(wornOutfitsByCategory)
            _ = UI.prompt("Press Enter to return to main menu: ")
            await show()
        } catch {
            UI.error("Error loading worn outfits: \(error.localizedDescription)")
            await show()
        }
    }

    private func showUnwornMenu() async {
        do {
            let unwornOutfitsByCategory = try await outfitService.getUnwornOutfits()

            if unwornOutfitsByCategory.isEmpty {
                UI.info("No unworn outfits found")
                await show()
                return
            }

            renderer.showUnwornOutfits(unwornOutfitsByCategory)
            _ = UI.prompt("Press Enter to return to main menu: ")
            await show()
        } catch {
            UI.error("Error loading unworn outfits: \(error.localizedDescription)")
            await show()
        }
    }

    private func handleManualSelection() async {
        do {
            let categories = try await outfitService.picker.getCategories()

            renderer.showManualSelectionCategories(categories)

            guard
                let categoryInput = UI.prompt(
                    "\nChoose a category (1-\(categories.count)) or 'q' to go back: ")
            else {
                await show()
                return
            }

            if categoryInput.lowercased() == "q" {
                await show()
                return
            }

            guard let categoryIndex = Int(categoryInput),
                categoryIndex > 0 && categoryIndex <= categories.count
            else {
                UI.error("Invalid category choice")
                await handleManualSelection()
                return
            }

            let selectedCategory = categories[categoryIndex - 1]
            let allOutfits = try await outfitService.picker.showAllOutfits(
                from: selectedCategory.name)

            if allOutfits.isEmpty {
                UI.info("No outfits found in \(selectedCategory.name)")
                await handleManualSelection()
                return
            }

            let state = try await outfitService.picker.getOutfitState(for: selectedCategory)
            let wornFileNames = Set(state.wornOutfits.map { $0.fileName })

            renderer.showManualSelectionOutfits(
                allOutfits, categoryName: selectedCategory.name, wornFileNames: wornFileNames)

            guard
                let outfitInput = UI.prompt(
                    "\nChoose an outfit (1-\(allOutfits.count)) or 'q' to go back: ")
            else {
                await show()
                return
            }

            if outfitInput.lowercased() == "q" {
                await handleManualSelection()
                return
            }

            guard let outfitIndex = Int(outfitInput),
                outfitIndex > 0 && outfitIndex <= allOutfits.count
            else {
                UI.error("Invalid outfit choice")
                await handleManualSelection()
                return
            }

            let selectedOutfit = allOutfits[outfitIndex - 1]
            let isWorn = wornFileNames.contains(selectedOutfit.fileName)

            // Present the manually selected outfit
            let result = await presentation.presentManualOutfit(
                selectedOutfit, category: selectedCategory.name, isWorn: isWorn)

            switch result {
            case .worn, .quit:
                print("👋 Goodbye!\n")
                return
            case .skipped:
                await handleManualSelection()
            }

        } catch {
            UI.error("Error: \(error.localizedDescription)")
            await show()
        }
    }
}
