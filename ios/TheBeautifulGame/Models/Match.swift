import Foundation

nonisolated enum MatchEventType: String, Codable, Sendable, Hashable {
    case goal, shot, save, yellowCard, redCard, substitution, injury
    case offside, corner, freeKick, penalty, halftime, fulltime, kickoff

    var icon: String {
        switch self {
        case .goal: "⚽"
        case .shot: "💨"
        case .save: "🚫"
        case .yellowCard: "🟨"
        case .redCard: "🟥"
        case .substitution: "🔄"
        case .injury: "🏥"
        case .offside: "📐"
        case .corner: "🏁"
        case .freeKick: "📋"
        case .penalty: "⚽"
        case .halftime: "⏸️"
        case .fulltime: "🏁"
        case .kickoff: "⚽"
        }
    }

    var isKeyEvent: Bool {
        switch self {
        case .goal, .yellowCard, .redCard, .injury, .penalty: true
        default: false
        }
    }
}

nonisolated enum MatchTeamSide: String, Codable, Sendable, Hashable {
    case home, away
}

nonisolated struct MatchEvent: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let minute: Int
    let type: MatchEventType
    let team: MatchTeamSide
    let playerName: String?
    let assistPlayerName: String?
    let description: String
}

nonisolated struct MatchStats: Codable, Sendable, Hashable {
    var possession: Int
    var shots: Int
    var shotsOnTarget: Int
    var corners: Int
    var fouls: Int
    var yellowCards: Int
    var redCards: Int
}

nonisolated struct PlayerMatchRating: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let playerName: String
    let position: String
    var rating: Double
    var goals: Int
    var assists: Int
    var tackles: Int
    var saves: Int
}

nonisolated enum MatchState: Codable, Sendable, Hashable {
    case upcoming
    case inProgress
    case halftime
    case finished
}

nonisolated struct MatchResult: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    var homeScore: Int
    var awayScore: Int
    var events: [MatchEvent]
    var homeStats: MatchStats
    var awayStats: MatchStats
    var playerRatings: [PlayerMatchRating]
    var state: MatchState
    let week: Int
    let competition: String
    let venue: String
    var currentMinute: Int
}

nonisolated struct Fixture: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let week: Int
    let competition: String
    let venue: String
    var result: MatchResult?
    var isPlayed: Bool
}
