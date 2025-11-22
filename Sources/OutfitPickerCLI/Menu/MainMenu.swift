import Foundation
import OutfitPickerCore

struct MainMenu {
    let outfitService: OutfitService
    let presentation: OutfitPresentation
    var session = OutfitSession()

    func show() async {
        do {
            let title = "👗 Outfit Picker"
            let titleWidth = 40
            let padding = (titleWidth - title.count) / 2
            let centeredTitle = String(repeating: " ", count: padding) + title

            print("\n\(UI.colorize(centeredTitle, UI.bold + UI.cyan))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")

            showOutfitDirectory()

            let categoryInfos = try await outfitService.picker.getCategoryInfo()
            let availableCategories = categoryInfos.filter { info in
                if case .hasOutfits = info.state { return true }
                return false
            }

            if !availableCategories.isEmpty {
                await showAvailableCategories(availableCategories)
            }

            await showUnavailableCategories(categoryInfos)
            print("\n")
            showMenuOptions()

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

    private func showOutfitDirectory() {
        do {
            let configService = ConfigService()
            let config = try configService.load()
            let absolutePath = URL(filePath: config.root).path(percentEncoded: false)
            print("📁 \(UI.colorize(absolutePath, UI.cyan))\n")
        } catch {
            print("")
        }
    }

    private func showMenuOptions() {
        print("📋 \(UI.colorize("Actions", UI.bold + UI.cyan))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")

        for choice in MenuChoice.allCases {
            let keyDisplay =
                "\(UI.colorize("[", UI.cyan))\(UI.colorize(choice.rawValue.uppercased(), UI.bold + UI.green))\(UI.colorize("]", UI.cyan))"
            print("  \(keyDisplay) \(choice.description)")
        }
    }

    private func showAvailableCategories(_ availableCategories: [CategoryInfo]) async {
        print("\n📂 \(UI.colorize("Available Categories", UI.bold + UI.blue))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.blue))")

        for (index, info) in availableCategories.enumerated() {
            do {
                let totalCount = try await outfitService.getActualOutfitCount(for: info.category)
                let availableCount = try await outfitService.picker.getAvailableCount(
                    for: info.category)
                let wornCount = totalCount - availableCount
                let statusText = "\(wornCount) of \(totalCount) outfits worn"
                let padding = String(repeating: " ", count: max(0, 20 - info.category.name.count))
                print(
                    "  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) 📁 \(info.category.name)\(padding) \(UI.colorize(statusText, UI.yellow))"
                )
            } catch {
                let padding = String(repeating: " ", count: max(0, 20 - info.category.name.count))
                print(
                    "  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) 📁 \(info.category.name)\(padding) \(UI.colorize(outfitCountText(info.outfitCount), UI.yellow))"
                )
            }
        }
    }

    private func showUnavailableCategories(_ categoryInfos: [CategoryInfo]) async {
        let excluded = categoryInfos.filter {
            if case .userExcluded = $0.state { return true }
            return false
        }
        let noAvatars = categoryInfos.filter {
            if case .empty = $0.state { return true }
            if case .noAvatarFiles = $0.state { return true }
            return false
        }

        let hasUnavailable = !excluded.isEmpty || !noAvatars.isEmpty

        if hasUnavailable {
            print("\n\(UI.colorize("⚠️  Unavailable Categories", UI.bold + UI.yellow))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.yellow))")
        }

        if !excluded.isEmpty {
            var excludedWithCounts: [String] = []
            for info in excluded {
                do {
                    let actualCount = try await outfitService.getActualOutfitCount(
                        for: info.category)
                    excludedWithCounts.append(
                        "\(info.category.name) (\(outfitCountText(actualCount)))")
                } catch {
                    excludedWithCounts.append(info.category.name)
                }
            }
            print(
                "  🚫 \(UI.colorize("Excluded:", UI.yellow)) \(excludedWithCounts.joined(separator: ", "))"
            )
        }

        if !noAvatars.isEmpty {
            print(
                "  📄 \(UI.colorize("No outfits found:", UI.yellow)) \(noAvatars.map { $0.category.name }.joined(separator: ", "))"
            )
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
        do {
            guard
                let randomOutfit = try await outfitService.picker.showRandomOutfitAcrossCategories()
            else {
                UI.info("No outfits available")
                await show()
                return
            }

            let result = await presentation.presentOutfitWithCategoryChoice(
                randomOutfit, category: randomOutfit.category.name)

            switch result {
            case .worn:
                await show()
                return
            case .quit:
                print("👋 Goodbye!\n")
                return
            case .skipped:
                await handleRandomOutfit()  // Try again with another random outfit
            }
        } catch {
            UI.error("Error: \(error.localizedDescription)")
            await show()
        }
    }

    private func showWornMenu() async {
        do {
            let wornOutfitsByCategory = try await outfitService.getWornOutfits2()

            if wornOutfitsByCategory.values.allSatisfy(\.isEmpty) {
                UI.info("No worn outfits found")
                await show()
                return
            }

            print("\n\n✅ \(UI.colorize("Worn Outfits", UI.bold + UI.green))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.green))")

            let sortedCategories = wornOutfitsByCategory.sorted { $0.key < $1.key }
            for (categoryName, outfits) in sortedCategories {
                print("\n📁 \(UI.colorize(categoryName, UI.bold + UI.blue)) (\(outfits.count) worn)")

                for outfit in outfits {
                    print("  • \(outfit)")
                }
            }

            print("\n")
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

            print("\n📄 \(UI.colorize("Unworn Outfits", UI.bold + UI.blue))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.blue))")

            let sortedCategories = unwornOutfitsByCategory.keys.sorted()
            for categoryName in sortedCategories {
                let outfits = unwornOutfitsByCategory[categoryName]!
                print(
                    "\n📁 \(UI.colorize(categoryName, UI.bold + UI.blue)) (\(outfits.count) unworn)")

                for outfit in outfits {
                    print("  • \(outfit.fileName)")
                }
            }

            print("\n")
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
            
            print("\n👕 \(UI.colorize("Choose Your Outfit", UI.bold + UI.cyan))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")
            
            // Show categories
            for (index, category) in categories.enumerated() {
                print("  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) 📁 \(category.name)")
            }
            
            guard let categoryInput = UI.prompt("\nChoose a category (1-\(categories.count)) or 'q' to go back: ") else {
                await show()
                return
            }
            
            if categoryInput.lowercased() == "q" {
                await show()
                return
            }
            
            guard let categoryIndex = Int(categoryInput), categoryIndex > 0 && categoryIndex <= categories.count else {
                UI.error("Invalid category choice")
                await handleManualSelection()
                return
            }
            
            let selectedCategory = categories[categoryIndex - 1]
            let allOutfits = try await outfitService.picker.showAllOutfits(from: selectedCategory)
            
            if allOutfits.isEmpty {
                UI.info("No outfits found in \(selectedCategory.name)")
                await handleManualSelection()
                return
            }
            
            print("\n👗 \(UI.colorize("Outfits in \(selectedCategory.name)", UI.bold + UI.blue))")
            print("\(UI.colorize(String(repeating: "─", count: 40), UI.blue))")
            
            let wornOutfits = try await outfitService.getWornOutfits()
            let wornInCategory = Set(wornOutfits[selectedCategory.name]?.map { $0.fileName } ?? [])
            
            for (index, outfit) in allOutfits.enumerated() {
                let cleanName = outfit.fileName.replacingOccurrences(of: ".avatar", with: "")
                let wornStatus = wornInCategory.contains(outfit.fileName) ? " \(UI.colorize("(worn)", UI.yellow))" : ""
                print("  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) \(cleanName)\(wornStatus)")
            }
            
            guard let outfitInput = UI.prompt("\nChoose an outfit (1-\(allOutfits.count)) or 'q' to go back: ") else {
                await show()
                return
            }
            
            if outfitInput.lowercased() == "q" {
                await handleManualSelection()
                return
            }
            
            guard let outfitIndex = Int(outfitInput), outfitIndex > 0 && outfitIndex <= allOutfits.count else {
                UI.error("Invalid outfit choice")
                await handleManualSelection()
                return
            }
            
            let selectedOutfit = allOutfits[outfitIndex - 1]
            let isWorn = wornInCategory.contains(selectedOutfit.fileName)
            
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

    private func outfitCountText(_ count: Int) -> String {
        return count == 1 ? "\(count) outfit" : "\(count) outfits"
    }
}
