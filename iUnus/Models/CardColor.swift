import SwiftUI

enum CardColor: String, Codable, CaseIterable, Identifiable, Equatable {
    case red, yellow, green, blue
    case wild

    var id: String { rawValue }

    var displayColor: Color {
        switch self {
        case .red: return Color(red: 0.85, green: 0.15, blue: 0.15)
        case .yellow: return Color(red: 0.95, green: 0.75, blue: 0.05)
        case .green: return Color(red: 0.13, green: 0.6, blue: 0.25)
        case .blue: return Color(red: 0.1, green: 0.35, blue: 0.75)
        case .wild: return Color.black
        }
    }

    static var playableColors: [CardColor] { [.red, .yellow, .green, .blue] }
}
