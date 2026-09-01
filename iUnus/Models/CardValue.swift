import Foundation

enum CardValue: Equatable, Codable, Hashable {
    case number(Int)
    case skip
    case reverse
    case drawTwo
    case wild
    case wildDrawFour

    var isWild: Bool {
        switch self {
        case .wild, .wildDrawFour: return true
        default: return false
        }
    }

    var isAction: Bool {
        switch self {
        case .skip, .reverse, .drawTwo, .wild, .wildDrawFour: return true
        default: return false
        }
    }

    var scoreValue: Int {
        switch self {
        case .number(let n): return n
        case .skip, .reverse, .drawTwo: return 20
        case .wild, .wildDrawFour: return 50
        }
    }

    var symbol: String {
        switch self {
        case .number(let n): return "\(n)"
        case .skip: return "⦸"
        case .reverse: return "⇄"
        case .drawTwo: return "+2"
        case .wild: return "★"
        case .wildDrawFour: return "+4"
        }
    }
}
