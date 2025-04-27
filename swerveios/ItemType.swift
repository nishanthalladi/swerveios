import Foundation

enum ItemType: CaseIterable {
//    case shield
    case timeSlow
//    case reverseControls
//    case heavyMode
    case mysteryBox
    case star
    case redShell
    case whirlpool
    case dragoonPart
    case lives
    case miniMode

    var emoji: String {
        switch self {
//        case .shield: return "⛨"
        case .timeSlow: return "⏲"
        case .mysteryBox: return "❔"
        case .star: return "⭐️"
        case .redShell: return "🚀"
        case .whirlpool: return "🌀"
        case .dragoonPart: return "🧩"
        case .lives: return "❤️"
        case .miniMode: return "📉"
//        case .reverseControls: return "🔄"
//        case .heavyMode: return "🪨"
        }
    }
}
