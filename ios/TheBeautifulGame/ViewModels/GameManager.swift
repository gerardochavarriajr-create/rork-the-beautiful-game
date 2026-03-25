import SwiftUI
import Foundation

@Observable
@MainActor
class GameManager {
    var phase: GamePhase = .onboarding
    var currentWeek: Int = 1
    var currentSeason: String = "2025/26"
    var managerName: String = "Manager"
    var selectedLeagueID: String?
    var userClubID: String?
    var league: LeagueData?
    var news: [NewsArticle] = []
    var shortlist: [String] = []
    var negotiations: [TransferOffer] = []
    var transferHistory: [TransferOffer] = []
    var trainingSchedule: [TrainingType] = [.technical, .attacking, .physical, .defending, .setPieces, .rest, .rest]
    var selectedFormation: Formation = Formation.allFormations[1]
    var lineupPlayerIDs: [String: String] = [:]
    var currentMatch: MatchResult?
    var matchSpeed: Double = 1.0
    var seasonResults: [MatchResult] = []
    var isSimulatingMatch: Bool = false
    var isAdvancingWeek: Bool = false
    var selectedTab: Int = 0

    var userClub: Club? {
        get {
            guard let id = userClubID else { return nil }
            return league?.clubs.first { $0.id == id }
        }
        set {
            guard let id = userClubID, let newValue, let index = league?.clubs.firstIndex(where: { $0.id == id }) else { return }
            league?.clubs[index] = newValue
        }
    }

    var nextFixture: Fixture? {
        guard let clubName = userClub?.name else { return nil }
        return league?.fixtures.first { !$0.isPlayed && ($0.homeTeam == clubName || $0.awayTeam == clubName) }
    }

    var currentWeekFixtures: [Fixture] {
        league?.fixtures.filter { $0.week == currentWeek } ?? []
    }

    var unreadNewsCount: Int {
        news.filter { !$0.isRead }.count
    }

    var leagueTable: [LeagueTableRow] {
        (league?.table ?? []).sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.goalDifference != rhs.goalDifference { return lhs.goalDifference > rhs.goalDifference }
            return lhs.goalsFor > rhs.goalsFor
        }
    }

    var userTablePosition: Int? {
        guard let name = userClub?.name else { return nil }
        return leagueTable.firstIndex { $0.teamName == name }.map { $0 + 1 }
    }

    var seasonRecord: (wins: Int, draws: Int, losses: Int) {
        let w = seasonResults.filter { isUserWin($0) }.count
        let d = seasonResults.filter { isUserDraw($0) }.count
        let l = seasonResults.filter { isUserLoss($0) }.count
        return (w, d, l)
    }

    var goalDifference: Int {
        var gf = 0, ga = 0
        for r in seasonResults {
            let isHome = r.homeTeam == userClub?.name
            gf += isHome ? r.homeScore : r.awayScore
            ga += isHome ? r.awayScore : r.homeScore
        }
        return gf - ga
    }

    var topScorer: (name: String, goals: Int)? {
        guard let players = userClub?.players else { return nil }
        let top = players.max { $0.seasonStats.goals < $1.seasonStats.goals }
        guard let top, top.seasonStats.goals > 0 else { return nil }
        return (top.shortName, top.seasonStats.goals)
    }

    func startCareer(leagueID: String, clubID: String, manager: String) {
        selectedLeagueID = leagueID
        userClubID = clubID
        managerName = manager

        let leagueInfo = DatabaseGenerator.generateLeagues().first { $0.id == leagueID }!
        var leagueData = DatabaseGenerator.generateLeagueData(for: leagueInfo)

        if let idx = leagueData.clubs.firstIndex(where: { $0.id == clubID }) {
            leagueData.clubs[idx].manager = ClubManager(name: manager, nationality: "England")
        }

        leagueData.table = leagueData.clubs.map { club in
            LeagueTableRow(teamName: club.name, isUserTeam: club.id == clubID)
        }

        league = leagueData
        phase = .playing
        selectedFormation = Formation.allFormations[1]

        let clubName = leagueData.clubs.first { $0.id == clubID }?.name ?? "your club"
        addNews(NewsArticle(
            id: UUID().uuidString,
            headline: "\(manager.uppercased()) APPOINTED AS NEW \(clubName.uppercased()) BOSS",
            subheadline: "New era begins at the club",
            body: "\(clubName) have confirmed the appointment of \(manager) as their new head coach. The board expressed confidence in the new manager's vision for the club. Fans are eagerly awaiting the start of the season.",
            date: "Week \(currentWeek)",
            source: "The Daily Tribune",
            type: .newspaper,
            isRead: false,
            week: currentWeek
        ))
    }

    func advanceWeek() {
        isAdvancingWeek = true
        simulateOtherMatches()
        applyTrainingEffects()
        processInjuries()
        processNegotiations()
        currentWeek += 1
        generateWeeklyNews()
        isAdvancingWeek = false
    }

    func autoFillLineup() {
        guard let club = userClub else { return }
        var newLineup: [String: String] = [:]
        var usedPlayers: Set<String> = []

        for slot in selectedFormation.slots {
            let candidates = club.players.filter { player in
                !usedPlayers.contains(player.id) &&
                !player.isInjured &&
                !player.isSuspended &&
                (player.primaryPosition == slot.position || player.primaryPosition.category == slot.position.category)
            }.sorted { $0.overallRating > $1.overallRating }

            if let best = candidates.first {
                newLineup[slot.id] = best.id
                usedPlayers.insert(best.id)
            }
        }
        lineupPlayerIDs = newLineup
    }

    func addNews(_ article: NewsArticle) {
        news.insert(article, at: 0)
    }

    private func simulateOtherMatches() {
        guard let leagueData = league else { return }
        let weekFixtures = leagueData.fixtures.filter { $0.week == currentWeek }

        for fixture in weekFixtures {
            guard !fixture.isPlayed else { continue }
            let isUserMatch = fixture.homeTeam == userClub?.name || fixture.awayTeam == userClub?.name
            guard !isUserMatch else { continue }

            let homePrestige = leagueData.clubs.first { $0.name == fixture.homeTeam }?.prestige ?? 5
            let awayPrestige = leagueData.clubs.first { $0.name == fixture.awayTeam }?.prestige ?? 5

            let homeGoals = simulateGoals(prestige: homePrestige, isHome: true)
            let awayGoals = simulateGoals(prestige: awayPrestige, isHome: false)

            if let idx = league?.fixtures.firstIndex(where: { $0.id == fixture.id }) {
                league?.fixtures[idx].isPlayed = true
                league?.fixtures[idx].result = MatchResult(
                    id: UUID().uuidString,
                    homeTeam: fixture.homeTeam,
                    awayTeam: fixture.awayTeam,
                    homeScore: homeGoals,
                    awayScore: awayGoals,
                    events: [],
                    homeStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
                    awayStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
                    playerRatings: [],
                    state: .finished,
                    week: currentWeek,
                    competition: fixture.competition,
                    venue: fixture.venue,
                    currentMinute: 90
                )
            }

            updateTable(home: fixture.homeTeam, away: fixture.awayTeam, homeGoals: homeGoals, awayGoals: awayGoals)
        }
    }

    func updateTable(home: String, away: String, homeGoals: Int, awayGoals: Int) {
        func update(_ teamName: String, gf: Int, ga: Int, isWin: Bool, isDraw: Bool) {
            guard let idx = league?.table.firstIndex(where: { $0.teamName == teamName }) else { return }
            league?.table[idx].played += 1
            league?.table[idx].goalsFor += gf
            league?.table[idx].goalsAgainst += ga
            if isWin { league?.table[idx].won += 1 }
            else if isDraw { league?.table[idx].drawn += 1 }
            else { league?.table[idx].lost += 1 }

            let result = isWin ? "W" : isDraw ? "D" : "L"
            league?.table[idx].form.append(result)
            if (league?.table[idx].form.count ?? 0) > 5 {
                league?.table[idx].form.removeFirst()
            }
        }

        let isDraw = homeGoals == awayGoals
        update(home, gf: homeGoals, ga: awayGoals, isWin: homeGoals > awayGoals, isDraw: isDraw)
        update(away, gf: awayGoals, ga: homeGoals, isWin: awayGoals > homeGoals, isDraw: isDraw)
    }

    private func simulateGoals(prestige: Int, isHome: Bool) -> Int {
        let base = Double(prestige) * 0.15 + (isHome ? 0.3 : 0.0)
        let goals = Int(base + Double.random(in: -0.5...1.5))
        return max(0, min(6, goals))
    }

    private func applyTrainingEffects() {
        guard var club = userClub else { return }
        for i in 0..<club.players.count {
            let change = Int.random(in: -1...2)
            club.players[i].currentFitness = min(100, max(40, club.players[i].currentFitness + change))
        }
        userClub = club
    }

    private func processInjuries() {
        guard var club = userClub else { return }
        for i in 0..<club.players.count {
            if club.players[i].isInjured {
                if let weeks = club.players[i].injuryWeeksRemaining, weeks <= 1 {
                    club.players[i].isInjured = false
                    club.players[i].injuryDescription = nil
                    club.players[i].injuryWeeksRemaining = nil
                } else if let weeks = club.players[i].injuryWeeksRemaining {
                    club.players[i].injuryWeeksRemaining = weeks - 1
                }
            } else if Int.random(in: 0...100) < 3 {
                let injuries = ["Hamstring strain", "Ankle sprain", "Knee injury", "Calf strain", "Groin injury"]
                club.players[i].isInjured = true
                club.players[i].injuryDescription = injuries.randomElement()!
                club.players[i].injuryWeeksRemaining = Int.random(in: 1...6)
                addNews(NewsArticle(
                    id: UUID().uuidString,
                    headline: "INJURY BLOW: \(club.players[i].fullName) out for \(club.players[i].injuryWeeksRemaining!) weeks",
                    subheadline: club.players[i].injuryDescription,
                    body: "\(club.name) have confirmed that \(club.players[i].fullName) has suffered a \(club.players[i].injuryDescription?.lowercased() ?? "injury") and will be out for approximately \(club.players[i].injuryWeeksRemaining!) weeks.",
                    date: "Week \(currentWeek)",
                    source: "Club Medical Staff",
                    type: .injury,
                    isRead: false,
                    week: currentWeek
                ))
            }
        }
        userClub = club
    }

    private func processNegotiations() {
        for i in 0..<negotiations.count {
            guard negotiations[i].status == .pending else { continue }
            let chance = Int.random(in: 0...100)
            if negotiations[i].offerAmount >= negotiations[i].askingPrice {
                negotiations[i].status = .accepted
            } else if chance < 30 {
                negotiations[i].status = .counterOffer
                negotiations[i].askingPrice = Int(Double(negotiations[i].askingPrice) * 0.95)
            } else if chance < 60 {
                negotiations[i].status = .rejected
            }
        }
    }

    private func generateWeeklyNews() {
        if let pos = userTablePosition {
            let headlines = [
                "\(userClub?.name ?? "Club") sit \(ordinal(pos)) after Week \(currentWeek)",
                "League update: \(leagueTable.first?.teamName ?? "Unknown") lead the way",
                "Matchday \(currentWeek) recap: Goals galore across the league"
            ]
            addNews(NewsArticle(
                id: UUID().uuidString,
                headline: headlines.randomElement()!,
                subheadline: nil,
                body: "After \(currentWeek) weeks of action, the league table is taking shape. \(leagueTable.first?.teamName ?? "The leaders") sit top with \(leagueTable.first?.points ?? 0) points.",
                date: "Week \(currentWeek)",
                source: ["The Daily Tribune", "Sports Echo", "Football Weekly", "The Athletic"].randomElement()!,
                type: .newspaper,
                isRead: false,
                week: currentWeek
            ))
        }
    }

    func recordMatchResult(_ result: MatchResult) {
        seasonResults.append(result)
        if let fixture = nextFixture, let idx = league?.fixtures.firstIndex(where: { $0.id == fixture.id }) {
            league?.fixtures[idx].isPlayed = true
            league?.fixtures[idx].result = result
        }
        updateTable(home: result.homeTeam, away: result.awayTeam, homeGoals: result.homeScore, awayGoals: result.awayScore)
        updatePlayerStats(from: result)
    }

    private func updatePlayerStats(from result: MatchResult) {
        guard var club = userClub else { return }
        for rating in result.playerRatings {
            if let idx = club.players.firstIndex(where: { $0.fullName == rating.playerName || $0.shortName == rating.playerName }) {
                club.players[idx].seasonStats.appearances += 1
                club.players[idx].seasonStats.goals += rating.goals
                club.players[idx].seasonStats.assists += rating.assists
                let oldAvg = club.players[idx].seasonStats.avgRating
                let apps = Double(club.players[idx].seasonStats.appearances)
                club.players[idx].seasonStats.avgRating = ((oldAvg * (apps - 1)) + rating.rating) / apps
            }
        }
        userClub = club
    }

    private func isUserWin(_ r: MatchResult) -> Bool {
        let isHome = r.homeTeam == userClub?.name
        return isHome ? r.homeScore > r.awayScore : r.awayScore > r.homeScore
    }

    private func isUserDraw(_ r: MatchResult) -> Bool {
        r.homeScore == r.awayScore
    }

    private func isUserLoss(_ r: MatchResult) -> Bool {
        let isHome = r.homeTeam == userClub?.name
        return isHome ? r.homeScore < r.awayScore : r.awayScore < r.homeScore
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 { suffix = "th" }
        else if ones == 1 { suffix = "st" }
        else if ones == 2 { suffix = "nd" }
        else if ones == 3 { suffix = "rd" }
        else { suffix = "th" }
        return "\(n)\(suffix)"
    }

    func save() {
        let save = GameSave(
            phase: phase,
            currentWeek: currentWeek,
            currentSeason: currentSeason,
            selectedLeagueID: selectedLeagueID,
            userClubID: userClubID,
            managerName: managerName,
            league: league,
            news: news,
            shortlist: shortlist,
            negotiations: negotiations,
            transferHistory: transferHistory,
            trainingSchedule: trainingSchedule,
            selectedFormation: selectedFormation,
            lineupPlayerIDs: lineupPlayerIDs,
            currentMatch: currentMatch,
            matchSpeed: matchSpeed,
            seasonResults: seasonResults
        )
        if let data = try? JSONEncoder().encode(save) {
            let url = URL.documentsDirectory.appending(path: "save.json")
            try? data.write(to: url)
        }
    }

    func load() -> Bool {
        let url = URL.documentsDirectory.appending(path: "save.json")
        guard let data = try? Data(contentsOf: url),
              let save = try? JSONDecoder().decode(GameSave.self, from: data) else { return false }
        phase = save.phase
        currentWeek = save.currentWeek
        currentSeason = save.currentSeason
        selectedLeagueID = save.selectedLeagueID
        userClubID = save.userClubID
        managerName = save.managerName
        league = save.league
        news = save.news
        shortlist = save.shortlist
        negotiations = save.negotiations
        transferHistory = save.transferHistory
        trainingSchedule = save.trainingSchedule
        selectedFormation = save.selectedFormation ?? Formation.allFormations[1]
        lineupPlayerIDs = save.lineupPlayerIDs
        currentMatch = save.currentMatch
        matchSpeed = save.matchSpeed
        seasonResults = save.seasonResults
        return true
    }
}
