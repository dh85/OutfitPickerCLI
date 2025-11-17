import Foundation

struct UI {
    enum Color: String {
        case reset = "\u{001B}[0m"
        case bold = "\u{001B}[1m"
        case green = "\u{001B}[32m"
        case blue = "\u{001B}[34m"
        case cyan = "\u{001B}[36m"
        case yellow = "\u{001B}[33m"
        case red = "\u{001B}[31m"
    }

    static let reset = Color.reset.rawValue
    static let bold = Color.bold.rawValue
    static let green = Color.green.rawValue
    static let blue = Color.blue.rawValue
    static let cyan = Color.cyan.rawValue
    static let yellow = Color.yellow.rawValue
    static let red = Color.red.rawValue

    static func header(_ title: String) {
        let separator = String(repeating: "─", count: title.count + 4)
        print("\n\(cyan)\(separator)\(reset)")
        print("\(cyan)─ \(bold)\(cyan)\(title)\(reset)\(cyan) ─\(reset)")
        print("\(cyan)\(separator)\(reset)\n")
    }

    static func colorize(_ text: String, _ color: String) -> String {
        return "\(color)\(text)\(reset)"
    }

    static func prompt(_ message: String) -> String? {
        print("\(colorize(message, bold))", terminator: "")
        return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func error(_ message: String) {
        print("❌ \(colorize(message, red))")
    }

    static func success(_ message: String) {
        print("✅ \(colorize(message, green))")
    }

    static func info(_ message: String) {
        print("ℹ️ \(message)")
    }
}
