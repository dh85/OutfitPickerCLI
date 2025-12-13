import Foundation
import OutfitPickerCore

struct MenuRenderer {

    func showTitle() {
        let title = "👗 Outfit Picker"
        let titleWidth = 40
        let padding = (titleWidth - title.count) / 2
        let centeredTitle = String(repeating: " ", count: padding) + title

        print("\n\(UI.colorize(centeredTitle, UI.bold + UI.cyan))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")
    }

    func showOutfitDirectory(path: String) {
        print("📁 \(UI.colorize(path, UI.cyan))\n")
    }

    func showAvailableCategories(_ availableCategories: [CategoryInfo], picker: OutfitPicker) async
    {
        print("\n📂 \(UI.colorize("Available Categories", UI.bold + UI.blue))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.blue))")

        for (index, info) in availableCategories.enumerated() {
            do {
                let state = try await picker.getOutfitState(for: info.category)
                let padding = String(repeating: " ", count: max(0, 20 - info.category.name.count))
                let statusText = "\(state.wornCount) of \(state.totalCount) outfits worn"
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

    func showUnavailableCategories(_ categoryInfos: [CategoryInfo], outfitService: OutfitService)
        async
    {
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
                "  📄 \(UI.colorize("No outfits found:", UI.yellow))"
            )
            for info in noAvatars {
                print("    - \(info.category.name) (Add .avatar files to \(info.category.path))")
            }
        }
    }

    func showMenuOptions() {
        print("📋 \(UI.colorize("Actions", UI.bold + UI.cyan))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")

        for choice in MenuChoice.allCases {
            let keyDisplay =
                "\(UI.colorize("[", UI.cyan))\(UI.colorize(choice.rawValue.uppercased(), UI.bold + UI.green))\(UI.colorize("]", UI.cyan))"
            print("  \(keyDisplay) \(choice.description)")
        }
    }

    func showWornOutfits(_ wornOutfitsByCategory: [String: [OutfitReference]]) {
        print("\n\n✅ \(UI.colorize("Worn Outfits", UI.bold + UI.green))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.green))")

        let sortedCategories = wornOutfitsByCategory.sorted { $0.key < $1.key }
        for (categoryName, outfits) in sortedCategories {
            print("\n📁 \(UI.colorize(categoryName, UI.bold + UI.blue)) (\(outfits.count) worn)")

            for outfit in outfits {
                let cleanName = outfit.fileName.replacingOccurrences(of: ".avatar", with: "")
                print("  • \(cleanName)")
            }
        }
        print("\n")
    }

    func showUnwornOutfits(_ unwornOutfitsByCategory: [String: [OutfitReference]]) {
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
    }

    func showManualSelectionCategories(_ categories: [CategoryReference]) {
        print("\n👕 \(UI.colorize("Choose Your Outfit", UI.bold + UI.cyan))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")

        for (index, category) in categories.enumerated() {
            print(
                "  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) 📁 \(category.name)"
            )
        }
    }

    func showManualSelectionOutfits(
        _ allOutfits: [OutfitReference], categoryName: String, wornFileNames: Set<String>
    ) {
        print("\n👗 \(UI.colorize("Outfits in \(categoryName)", UI.bold + UI.blue))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.blue))")

        for (index, outfit) in allOutfits.enumerated() {
            let cleanName = outfit.fileName.replacingOccurrences(of: ".avatar", with: "")
            let wornStatus =
                wornFileNames.contains(outfit.fileName)
                ? " \(UI.colorize("(worn)", UI.yellow))" : ""
            print(
                "  \(UI.colorize("[", UI.cyan))\(UI.colorize("\(index + 1)", UI.bold + UI.green))\(UI.colorize("]", UI.cyan)) \(cleanName)\(wornStatus)"
            )
        }
    }

    private func outfitCountText(_ count: Int) -> String {
        return count == 1 ? "\(count) outfit" : "\(count) outfits"
    }
}
