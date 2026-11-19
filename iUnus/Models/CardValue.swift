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

    /// The draw amount if this is a stackable penalty card (Draw Two / Wild Draw Four), else nil.
    var drawPenaltyAmount: Int? {
        switch self {
        case .drawTwo: return 2
        case .wildDrawFour: return 4
        default: return nil
        }
    }

    var scoreValue: Int {
        switch self {
        case .number(let n): return n
        case .skip, .reverse, .drawTwo: return 20
        case .wild, .wildDrawFour: return 50
        }
    }

    /// 6 and 9 are underlined so they can't be confused with each other upside down.
    var needsOrientationMark: Bool { self == .number(6) || self == .number(9) }

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
