import Foundation

nonisolated struct Stadium: Codable, Sendable, Hashable {
    let name: String
    let capacity: Int
}

nonisolated struct ClubBudget: Codable, Sendable, Hashable {
    var transfer: Int
    var wage: Int
    var total: Int
}

nonisolated struct ClubManager: Codable, Sendable, Hashable {
    var name: String
    var nationality: String
}

struct Club: Identifiable, Codable, Sendable, Hashable {
    let id: String
    var name: String
    var shortName: String
    var city: String
    var stadium: Stadium
    var league: String
    var prestige: Int
    var primaryColor: String
    var secondaryColor: String
    var budget: ClubBudget
    var boardConfidence: Int
    var manager: ClubManager
    var players: [Player]
    var seasonObjectives: [String]

    var totalWageBill: Int {
        players.reduce(0) { $0 + $1.weeklyWage }
    }

    var squadValue: Int {
        players.reduce(0) { $0 + $1.marketValue }
    }
}
