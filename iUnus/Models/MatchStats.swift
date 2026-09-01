import Foundation
import Combine

struct MatchStats: Codable, Equatable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var bestScore: Int = 0
}

@MainActor
final class MatchStatsStore: ObservableObject {
    static let shared = MatchStatsStore()

    @Published private(set) var stats: MatchStats {
        didSet { persist() }
    }

    private static let storageKey = "app.matchStats"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(MatchStats.self, from: data) {
            stats = decoded
        } else {
            stats = MatchStats()
        }
    }

    func recordGameEnd(humanWon: Bool, humanScore: Int) {
        stats.gamesPlayed += 1
        if humanWon {
            stats.gamesWon += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)
        } else {
            stats.currentStreak = 0
        }
        stats.bestScore = max(stats.bestScore, humanScore)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
