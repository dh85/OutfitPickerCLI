import Foundation

enum MenuChoice: String, CaseIterable {
    case random = "r"
    case manual = "m"
    case worn = "w"
    case unworn = "u"
    case advanced = "a"
    case quit = "q"

    var description: String {
        switch self {
        case .random: return "🎲 Pick a random outfit"
        case .manual: return "👕 Choose an outfit manually"
        case .worn: return "✅ Show outfits I've already worn"
        case .unworn: return "📄 Show outfits I haven't worn yet"
        case .advanced: return "🔧 Advanced settings"
        case .quit: return "👋 Exit"
        }
    }
}

enum AdvancedChoice: String, CaseIterable {
    case changePath = "p"
    case changeLanguage = "l"
    case changeExcluded = "e"
    case resetCategory = "c"
    case resetAll = "r"
    case resetSettings = "s"
    case back = "b"
    case quit = "q"

    var description: String {
        switch self {
        case .changePath: return "Change outfit path"
        case .changeLanguage: return "Change language"
        case .changeExcluded: return "Manage categories excluded from random selection"
        case .resetCategory: return "Reset worn outfits for category"
        case .resetAll: return "Reset all worn outfits"
        case .resetSettings: return "Reset user settings and worn outfits"
        case .back: return "Back to main menu"
        case .quit: return "Quit"
        }
    }
}

enum OutfitChoice {
    case worn, skipped, quit
}
