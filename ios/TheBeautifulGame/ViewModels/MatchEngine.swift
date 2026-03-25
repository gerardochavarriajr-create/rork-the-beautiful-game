import SwiftUI
import Foundation

@Observable
@MainActor
class MatchEngine {
    var matchResult: MatchResult?
    var isSimulating: Bool = false
    var speed: Double = 1.0
    private var simulationTask: Task<Void, Never>?

    func startMatch(home: String, away: String, homeClub: Club?, awayClub: Club?, week: Int, competition: String, venue: String, lineup: [String: String], formation: Formation, gameManager: GameManager) {
        let homePrestige = homeClub?.prestige ?? 5
        let awayPrestige = awayClub?.prestige ?? 5

        matchResult = MatchResult(
            id: UUID().uuidString,
            homeTeam: home,
            awayTeam: away,
            homeScore: 0,
            awayScore: 0,
            events: [],
            homeStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
            awayStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
            playerRatings: generateInitialRatings(homeClub: homeClub, awayClub: awayClub, lineup: lineup, formation: formation, isUserHome: home == gameManager.userClub?.name),
            state: .inProgress,
            week: week,
            competition: competition,
            venue: venue,
            currentMinute: 0
        )

        addEvent(minute: 0, type: .kickoff, team: .home, description: "Kick-off! The match is underway.")
        isSimulating = true

        simulationTask = Task {
            await simulateMatch(homePrestige: homePrestige, awayPrestige: awayPrestige, homeClub: homeClub, awayClub: awayClub)
        }
    }

    func stopSimulation() {
        simulationTask?.cancel()
        isSimulating = false
    }

    func instantResult() {
        guard var result = matchResult, result.state != .finished else { return }
        stopSimulation()
        while result.currentMinute < 90 {
            result.currentMinute += 1
        }
        result.state = .finished
        matchResult = result
        addEvent(minute: 90, type: .fulltime, team: .home, description: "Full time! The final whistle blows.")
    }

    private func simulateMatch(homePrestige: Int, awayPrestige: Int, homeClub: Club?, awayClub: Club?) async {
        let homePlayers = homeClub?.players.filter { !$0.isInjured && !$0.isSuspended } ?? []
        let awayPlayers = awayClub?.players.filter { !$0.isInjured && !$0.isSuspended } ?? []

        for minute in 1...90 {
            guard !Task.isCancelled else { return }

            let delay = max(0.02, 0.3 / speed)
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))

            matchResult?.currentMinute = minute

            if minute == 45 {
                matchResult?.state = .halftime
                addEvent(minute: 45, type: .halftime, team: .home, description: "Half time! The referee blows for the break.")
                let htDelay = max(0.5, 2.0 / speed)
                try? await Task.sleep(for: .milliseconds(Int(htDelay * 1000)))
                matchResult?.state = .inProgress
            }

            let eventChance = Int.random(in: 0...100)

            if eventChance < 3 {
                let isHome = Bool.random() ? (Int.random(in: 0...10) < 5 + homePrestige - awayPrestige) : false
                let team: MatchTeamSide = isHome ? .home : .away
                let players = isHome ? homePlayers : awayPlayers
                let scorers = players.filter { $0.primaryPosition.category == .attacker || $0.primaryPosition.category == .midfielder }
                let scorer = scorers.randomElement() ?? players.randomElement()
                let assisters = players.filter { $0.id != scorer?.id }
                let assister = assisters.randomElement()

                if isHome {
                    matchResult?.homeScore += 1
                    matchResult?.homeStats.shotsOnTarget += 1
                } else {
                    matchResult?.awayScore += 1
                    matchResult?.awayStats.shotsOnTarget += 1
                }

                let descriptions = [
                    "GOAL! \(scorer?.shortName ?? "Unknown") fires it into the back of the net!",
                    "GOAL! Brilliant finish from \(scorer?.shortName ?? "Unknown")!",
                    "GOAL! \(scorer?.shortName ?? "Unknown") makes no mistake from close range!",
                    "GOAL! A thunderous strike from \(scorer?.shortName ?? "Unknown")!"
                ]
                addEvent(minute: minute, type: .goal, team: team, playerName: scorer?.shortName, assistPlayerName: assister?.shortName, description: descriptions.randomElement()!)

                if let scorerName = scorer?.shortName {
                    if let idx = matchResult?.playerRatings.firstIndex(where: { $0.playerName == scorerName }) {
                        matchResult?.playerRatings[idx].goals += 1
                        matchResult?.playerRatings[idx].rating = min(10.0, (matchResult?.playerRatings[idx].rating ?? 6.5) + 0.5)
                    }
                }
            } else if eventChance < 8 {
                let isHome = Bool.random()
                let team: MatchTeamSide = isHome ? .home : .away
                let players = isHome ? homePlayers : awayPlayers
                let shooter = players.randomElement()
                if isHome { matchResult?.homeStats.shots += 1 } else { matchResult?.awayStats.shots += 1 }
                addEvent(minute: minute, type: .shot, team: team, playerName: shooter?.shortName, description: "\(shooter?.shortName ?? "Unknown") shoots but it goes wide.")
            } else if eventChance < 10 {
                let isHome = Bool.random()
                let team: MatchTeamSide = isHome ? .home : .away
                let players = isHome ? homePlayers : awayPlayers
                let player = players.randomElement()
                if isHome { matchResult?.homeStats.fouls += 1 } else { matchResult?.awayStats.fouls += 1 }
                addEvent(minute: minute, type: .yellowCard, team: team, playerName: player?.shortName, description: "Yellow card shown to \(player?.shortName ?? "Unknown") for a reckless challenge.")
                if isHome { matchResult?.homeStats.yellowCards += 1 } else { matchResult?.awayStats.yellowCards += 1 }
            } else if eventChance < 11 {
                let isHome = Bool.random()
                let team: MatchTeamSide = isHome ? .home : .away
                if isHome { matchResult?.homeStats.corners += 1 } else { matchResult?.awayStats.corners += 1 }
                addEvent(minute: minute, type: .corner, team: team, description: "Corner kick awarded.")
            }

            let totalShots = (matchResult?.homeStats.shots ?? 0) + (matchResult?.awayStats.shots ?? 0)
            if totalShots > 0 {
                let homePoss = 45 + (homePrestige - awayPrestige) * 2 + Int.random(in: -5...5)
                matchResult?.homeStats.possession = max(30, min(70, homePoss))
                matchResult?.awayStats.possession = 100 - (matchResult?.homeStats.possession ?? 50)
            }
        }

        matchResult?.state = .finished
        matchResult?.currentMinute = 90
        addEvent(minute: 90, type: .fulltime, team: .home, description: "Full time! The final whistle blows. \(matchResult?.homeTeam ?? "") \(matchResult?.homeScore ?? 0) - \(matchResult?.awayScore ?? 0) \(matchResult?.awayTeam ?? "")")
        isSimulating = false
    }

    private func addEvent(minute: Int, type: MatchEventType, team: MatchTeamSide, playerName: String? = nil, assistPlayerName: String? = nil, description: String) {
        let event = MatchEvent(
            id: UUID().uuidString,
            minute: minute,
            type: type,
            team: team,
            playerName: playerName,
            assistPlayerName: assistPlayerName,
            description: description
        )
        matchResult?.events.append(event)
    }

    private func generateInitialRatings(homeClub: Club?, awayClub: Club?, lineup: [String: String], formation: Formation, isUserHome: Bool) -> [PlayerMatchRating] {
        var ratings: [PlayerMatchRating] = []
        let userClub = isUserHome ? homeClub : awayClub

        if let club = userClub {
            for slot in formation.slots {
                if let playerID = lineup[slot.id],
                   let player = club.players.first(where: { $0.id == playerID }) {
                    ratings.append(PlayerMatchRating(
                        id: UUID().uuidString,
                        playerName: player.shortName,
                        position: slot.position.rawValue,
                        rating: 6.0 + Double.random(in: 0...1.0),
                        goals: 0, assists: 0, tackles: 0, saves: 0
                    ))
                }
            }
        }
        return ratings
    }
}
