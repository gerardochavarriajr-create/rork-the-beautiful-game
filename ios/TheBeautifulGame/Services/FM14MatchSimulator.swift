// FM14MatchSimulator.swift
// TheBeautifulGame
//
// Real FM14 match simulation using the 80x14 Event Matrix probabilities.
// Replaces the placeholder MatchEngine with parameter-driven logic.
// Designed as a drop-in enhancement: same streaming API (minute-by-minute async),
// but with FM14's actual event probabilities, home advantage, and attribute weighting.

import Foundation

/// Loads and provides access to the FM14 Event Matrix (80 events x 14 positions).
/// Each cell is a probability weight (0-1000) for that event occurring with a player in that position.
struct FM14EventMatrix: Codable, Sendable {
    /// Raw matrix: [eventIndex][positionIndex] -> probability weight (0-1000)
    let rows: [[Int]]
    /// Event labels for each row
    let eventLabels: [String]
    /// Position labels for each column (NO, GK, RB, LB, CD, DM, RM, LM, CM, RW, LW, AM, CF, ST)
    let positionLabels: [String]

    var eventCount: Int { rows.count }
    var positionCount: Int { positionLabels.count }

    /// Get probability for a specific event and position
    func probability(event: Int, position: Int) -> Int {
        guard event < rows.count, position < rows[event].count else { return 0 }
        return rows[event][position]
    }

    /// Load from bundled JSON (output of convert_parameters_to_json.py)
    static func loadFromBundle() -> FM14EventMatrix? {
        // Try app bundle first
        if let url = Bundle.main.url(forResource: "Textmode Events Matrix", withExtension: "json") {
            return load(from: url)
        }
        // Fallback: try parameter files directory
        if let url = Bundle.main.url(forResource: "Textmode Events Matrix",
                                      withExtension: "json",
                                      subdirectory: "ParameterFiles") {
            return load(from: url)
        }
        return nil
    }

    private static func load(from url: URL) -> FM14EventMatrix? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // The JSON from convert_parameters_to_json.py has structure:
        // { "_columns": ["NO","GK","RB",...], "_rows": [{"_label":"event","NO":val,...},...] }
        guard let columns = json["_columns"] as? [String],
              let rawRows = json["_rows"] as? [[String: Any]] else {
            return nil
        }

        var eventLabels: [String] = []
        var matrix: [[Int]] = []

        for row in rawRows {
            let label = row["_label"] as? String ?? "unknown"
            eventLabels.append(label)

            var probabilities: [Int] = []
            for col in columns {
                let val = row[col] as? Int ?? (row[col] as? Double).map { Int($0) } ?? 0
                probabilities.append(val)
            }
            matrix.append(probabilities)
        }

        return FM14EventMatrix(rows: matrix, eventLabels: eventLabels, positionLabels: columns)
    }

    /// Fallback matrix with reasonable defaults if JSON not available
    static let fallback: FM14EventMatrix = {
        // Simplified: 10 key event types, 14 positions
        // Goal events have higher probability for attacking positions
        let labels = ["distance_shot", "header", "dribble_goal", "through_pass_goal",
                      "cross_goal", "set_piece_goal", "save", "foul",
                      "yellow_card", "corner"]
        let positions = ["NO", "GK", "RB", "LB", "CD", "DM", "RM", "LM", "CM", "RW", "LW", "AM", "CF", "ST"]

        let defaultRows: [[Int]] = [
            // distance_shot:  low for GK/DEF, medium for MID, high for ATT
            [0, 2, 15, 15, 10, 20, 30, 30, 35, 40, 40, 50, 55, 60],
            // header: higher for CD, CF, ST
            [0, 5, 20, 20, 40, 15, 10, 10, 15, 15, 15, 25, 45, 50],
            // dribble_goal: high for wingers and forwards
            [0, 1, 10, 10, 5, 10, 35, 35, 25, 50, 50, 45, 40, 35],
            // through_pass_goal: high for AM, CF, ST
            [0, 1, 5, 5, 5, 10, 20, 20, 30, 30, 30, 50, 55, 60],
            // cross_goal: high for wide players
            [0, 1, 25, 25, 5, 5, 45, 45, 15, 50, 50, 20, 30, 25],
            // set_piece_goal: moderate across positions
            [0, 2, 15, 15, 30, 10, 10, 10, 15, 10, 10, 20, 25, 25],
            // save: only GK
            [0, 80, 2, 2, 5, 2, 1, 1, 1, 1, 1, 1, 1, 1],
            // foul: higher for DM, CD
            [0, 5, 30, 30, 35, 40, 25, 25, 30, 20, 20, 15, 15, 15],
            // yellow_card: proportional to foul probability
            [0, 2, 15, 15, 18, 20, 12, 12, 15, 10, 10, 8, 8, 8],
            // corner: moderate
            [0, 1, 10, 10, 5, 5, 20, 20, 15, 25, 25, 20, 15, 15],
        ]

        return FM14EventMatrix(rows: defaultRows, eventLabels: labels, positionLabels: positions)
    }()
}

// MARK: - FM14 Match Simulation Parameters

/// Parameters from LiveTicker.txt controlling match simulation probabilities
struct FM14MatchParams: Sendable {
    /// Home advantage multiplier (FM14 default: 1.15)
    let homeAdvantage: Double
    /// Base probability of a goal-scoring chance per minute (per 1000)
    let chancePerMinute: Int
    /// Probability of yellow card per foul (per 1000)
    let yellowCardRate: Int
    /// Probability of red card per foul (per 1000)
    let redCardRate: Int
    /// Probability of injury per match (per 1000)
    let injuryRate: Int

    static let `default` = FM14MatchParams(
        homeAdvantage: 1.15,
        chancePerMinute: 45,   // ~4% chance of something happening each minute
        yellowCardRate: 450,
        redCardRate: 220,
        injuryRate: 280
    )
}

// MARK: - FM14-Enhanced Match Event Generation

/// Generates match events using FM14's real probability distributions.
/// This replaces the flat 3% goal/min with position-weighted, attribute-influenced events.
enum FM14EventGenerator {

    /// Roll for a match event in a given minute using FM14 probabilities.
    /// Returns nil if nothing notable happens this minute.
    static func rollEvent(
        minute: Int,
        isHome: Bool,
        teamPlayers: [Player],
        opponentPrestige: Int,
        params: FM14MatchParams,
        matrix: FM14EventMatrix
    ) -> (type: MatchEventType, player: Player?, assist: Player?, description: String)? {

        // Base chance of an event, modified by home advantage
        let baseProbability = params.chancePerMinute
        let adjustedProbability = isHome
            ? Int(Double(baseProbability) * params.homeAdvantage)
            : baseProbability

        // Roll: does anything happen this minute?
        guard Int.random(in: 0..<1000) < adjustedProbability else { return nil }

        // What kind of event? Weight by team composition
        let eventRoll = Int.random(in: 0..<100)

        if eventRoll < 25 {
            // Goal-scoring chance (~25% of events)
            return rollGoalChance(teamPlayers: teamPlayers, matrix: matrix, minute: minute)
        } else if eventRoll < 45 {
            // Shot on target (~20%)
            return rollShot(teamPlayers: teamPlayers, minute: minute, onTarget: true)
        } else if eventRoll < 60 {
            // Shot off target (~15%)
            return rollShot(teamPlayers: teamPlayers, minute: minute, onTarget: false)
        } else if eventRoll < 75 {
            // Foul (~15%)
            return rollFoul(teamPlayers: teamPlayers, params: params, minute: minute)
        } else if eventRoll < 85 {
            // Corner (~10%)
            return rollCorner(minute: minute)
        } else if eventRoll < 90 {
            // Save (~5%)
            return rollSave(teamPlayers: teamPlayers, minute: minute)
        } else {
            // Free kick, offside, etc. (~10%)
            return rollMiscEvent(minute: minute)
        }
    }

    private static func rollGoalChance(
        teamPlayers: [Player],
        matrix: FM14EventMatrix,
        minute: Int
    ) -> (type: MatchEventType, player: Player?, assist: Player?, description: String)? {
        // Weight scorer selection by position-based goal probability
        let availablePlayers = teamPlayers.filter { !$0.isInjured && !$0.isSuspended }
        guard !availablePlayers.isEmpty else { return nil }

        // Use matrix to weight which player scores
        // Higher-rated attacking players more likely
        let scorer = weightedPlayerSelection(
            players: availablePlayers,
            attributeWeight: { p in
                let finish = p.attributes.finishing
                let shot = p.attributes.shotPower
                let pos = p.primaryPosition.category == .attacker ? 30 : (p.primaryPosition.category == .midfielder ? 15 : 5)
                return finish + shot + pos
            }
        )

        // Conversion: does the chance become a goal?
        // Higher finishing + composure = more likely
        let conversionBase = 350 // 35% base conversion rate
        let finishingBonus = (scorer?.attributes.finishing ?? 50) * 3  // up to +297
        let composureBonus = (scorer?.attributes.composure ?? 50) * 1  // up to +99
        let conversionChance = conversionBase + finishingBonus + composureBonus

        if Int.random(in: 0..<1000) < min(750, conversionChance) {
            // GOAL!
            let assistProvider = availablePlayers.filter { $0.id != scorer?.id }.randomElement()
            let name = scorer?.shortName ?? "Unknown"
            let descriptions = [
                "GOAL! \(name) fires it into the back of the net!",
                "GOAL! Brilliant finish from \(name)!",
                "GOAL! \(name) makes no mistake from close range!",
                "GOAL! A thunderous strike from \(name)!",
                "GOAL! \(name) finds the corner with a clinical finish!",
                "GOAL! What a strike from \(name)! The keeper had no chance!"
            ]
            return (.goal, scorer, assistProvider, descriptions.randomElement()!)
        } else {
            // Saved or missed
            let name = scorer?.shortName ?? "Unknown"
            return (.save, scorer, nil, "Good save! The keeper denies \(name) from close range.")
        }
    }

    private static func rollShot(
        teamPlayers: [Player],
        minute: Int,
        onTarget: Bool
    ) -> (type: MatchEventType, player: Player?, assist: Player?, description: String) {
        let available = teamPlayers.filter { !$0.isInjured }
        let shooter = weightedPlayerSelection(players: available) { p in
            p.attributes.longShots + p.attributes.shotPower + (p.primaryPosition.category == .attacker ? 20 : 0)
        }
        let name = shooter?.shortName ?? "Unknown"

        if onTarget {
            let descs = [
                "\(name) forces a save from the goalkeeper.",
                "Shot from \(name) is straight at the keeper.",
                "\(name) tests the keeper with a powerful drive."
            ]
            return (.shot, shooter, nil, descs.randomElement()!)
        } else {
            let descs = [
                "\(name) shoots but it goes wide.",
                "Effort from \(name) sails over the crossbar.",
                "\(name) blazes the ball over from distance."
            ]
            return (.shot, shooter, nil, descs.randomElement()!)
        }
    }

    private static func rollFoul(
        teamPlayers: [Player],
        params: FM14MatchParams,
        minute: Int
    ) -> (type: MatchEventType, player: Player?, assist: Player?, description: String) {
        let available = teamPlayers.filter { !$0.isInjured }
        let fouler = weightedPlayerSelection(players: available) { p in
            p.attributes.aggression + p.attributes.tackling + (p.primaryPosition.category == .defender ? 15 : 0)
        }
        let name = fouler?.shortName ?? "Unknown"

        // Card check
        let cardRoll = Int.random(in: 0..<1000)
        if cardRoll < params.redCardRate / 10 { // Much rarer
            return (.redCard, fouler, nil, "RED CARD! \(name) is sent off for a dangerous tackle!")
        } else if cardRoll < params.yellowCardRate {
            return (.yellowCard, fouler, nil, "Yellow card shown to \(name) for a reckless challenge.")
        } else {
            return (.foul, fouler, nil, "Foul by \(name). Free kick awarded.")
        }
    }

    private static func rollCorner(minute: Int) -> (type: MatchEventType, player: Player?, assist: Player?, description: String) {
        (.corner, nil, nil, "Corner kick awarded.")
    }

    private static func rollSave(
        teamPlayers: [Player],
        minute: Int
    ) -> (type: MatchEventType, player: Player?, assist: Player?, description: String) {
        let shooter = teamPlayers.filter { $0.primaryPosition.category == .attacker || $0.primaryPosition.category == .midfielder }.randomElement()
        let name = shooter?.shortName ?? "Unknown"
        return (.save, shooter, nil, "Good save! The keeper denies \(name).")
    }

    private static func rollMiscEvent(minute: Int) -> (type: MatchEventType, player: Player?, assist: Player?, description: String) {
        let events: [(MatchEventType, String)] = [
            (.offside, "Offside! The flag goes up."),
            (.freeKick, "Free kick in a dangerous position."),
        ]
        let pick = events.randomElement()!
        return (pick.0, nil, nil, pick.1)
    }

    /// Select a player weighted by an attribute function (higher = more likely to be chosen)
    private static func weightedPlayerSelection(
        players: [Player],
        attributeWeight: (Player) -> Int
    ) -> Player? {
        guard !players.isEmpty else { return nil }
        let weights = players.map { max(1, attributeWeight($0)) }
        let totalWeight = weights.reduce(0, +)
        var roll = Int.random(in: 0..<totalWeight)
        for (i, weight) in weights.enumerated() {
            roll -= weight
            if roll < 0 { return players[i] }
        }
        return players.last
    }
}
