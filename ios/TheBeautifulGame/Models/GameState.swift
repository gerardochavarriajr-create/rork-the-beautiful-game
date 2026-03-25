import Foundation

nonisolated enum GamePhase: String, Codable, Sendable {
    case onboarding
    case playing
}

nonisolated enum TrainingType: String, Codable, Sendable, CaseIterable, Hashable {
    case attacking = "Attacking"
    case defending = "Defending"
    case physical = "Physical"
    case technical = "Technical"
    case setPieces = "Set Pieces"
    case rest = "Rest"

    var icon: String {
        switch self {
        case .attacking: "flame.fill"
        case .defending: "shield.fill"
        case .physical: "figure.run"
        case .technical: "sportscourt.fill"
        case .setPieces: "flag.fill"
        case .rest: "bed.double.fill"
        }
    }
}

nonisolated struct TransferOffer: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let playerID: String
    let playerName: String
    let fromClub: String
    let toClub: String
    var offerAmount: Int
    var askingPrice: Int
    var weeklyWage: Int
    var contractYears: Int
    var status: TransferStatus
    let week: Int
}

nonisolated enum TransferStatus: String, Codable, Sendable, Hashable {
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case counterOffer = "Counter-Offer"
    case completed = "Completed"
}

nonisolated struct GameSave: Codable, Sendable {
    var phase: GamePhase
    var currentWeek: Int
    var currentSeason: String
    var selectedLeagueID: String?
    var userClubID: String?
    var managerName: String
    var league: LeagueData?
    var news: [NewsArticle]
    var shortlist: [String]
    var negotiations: [TransferOffer]
    var transferHistory: [TransferOffer]
    var trainingSchedule: [TrainingType]
    var selectedFormation: Formation?
    var lineupPlayerIDs: [String: String]
    var currentMatch: MatchResult?
    var matchSpeed: Double
    var seasonResults: [MatchResult]
}
