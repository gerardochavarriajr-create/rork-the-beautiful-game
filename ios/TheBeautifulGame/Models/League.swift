import Foundation

nonisolated struct LeagueTableRow: Identifiable, Codable, Sendable, Hashable {
    var id: String { teamName }
    let teamName: String
    var played: Int
    var won: Int
    var drawn: Int
    var lost: Int
    var goalsFor: Int
    var goalsAgainst: Int
    var isUserTeam: Bool

    var goalDifference: Int { goalsFor - goalsAgainst }
    var points: Int { won * 3 + drawn }
    var form: [String]

    init(teamName: String, played: Int = 0, won: Int = 0, drawn: Int = 0, lost: Int = 0, goalsFor: Int = 0, goalsAgainst: Int = 0, isUserTeam: Bool = false, form: [String] = []) {
        self.teamName = teamName
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.isUserTeam = isUserTeam
        self.form = form
    }
}

nonisolated struct LeagueInfo: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let name: String
    let country: String
    let flagEmoji: String
    let teamCount: Int
}

nonisolated struct LeagueData: Codable, Sendable {
    let info: LeagueInfo
    var table: [LeagueTableRow]
    var fixtures: [Fixture]
    var clubs: [Club]
}
