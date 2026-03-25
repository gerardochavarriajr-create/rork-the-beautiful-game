import Foundation

nonisolated struct PlayerAttributes: Codable, Sendable, Hashable {
    var ballControl: Int
    var crossing: Int
    var dribbling: Int
    var finishing: Int
    var heading: Int
    var longShots: Int
    var marking: Int
    var passing: Int
    var setPieces: Int
    var shotPower: Int
    var tackling: Int
    var technique: Int
    var throwing: Int

    var acceleration: Int
    var agility: Int
    var balance: Int
    var jumping: Int
    var pace: Int
    var stamina: Int
    var strength: Int
    var fitness: Int

    var aggression: Int
    var anticipation: Int
    var composure: Int
    var concentration: Int
    var creativity: Int
    var decisions: Int
    var determination: Int
    var flair: Int
    var leadership: Int
    var positioning: Int
    var workRate: Int

    var aerialAbility: Int
    var commandOfArea: Int
    var communication: Int
    var handling: Int
    var kicking: Int
    var oneOnOnes: Int
    var reflexes: Int
    var rushingOut: Int

    var technicalAverage: Double {
        let vals = [ballControl, crossing, dribbling, finishing, heading, longShots, marking, passing, setPieces, shotPower, tackling, technique, throwing]
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var physicalAverage: Double {
        let vals = [acceleration, agility, balance, jumping, pace, stamina, strength, fitness]
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var mentalAverage: Double {
        let vals = [aggression, anticipation, composure, concentration, creativity, decisions, determination, flair, leadership, positioning, workRate]
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var goalkeepingAverage: Double {
        let vals = [aerialAbility, commandOfArea, communication, handling, kicking, oneOnOnes, reflexes, rushingOut]
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }
}

nonisolated enum PlayerPosition: String, Codable, Sendable, CaseIterable, Hashable, Identifiable {
    case GK, RB, LB, CB, DM, RM, LM, CM, RW, LW, AM, CF, ST

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .GK: "Goalkeeper"
        case .RB: "Right Back"
        case .LB: "Left Back"
        case .CB: "Centre Back"
        case .DM: "Defensive Mid"
        case .RM: "Right Mid"
        case .LM: "Left Mid"
        case .CM: "Central Mid"
        case .RW: "Right Wing"
        case .LW: "Left Wing"
        case .AM: "Attacking Mid"
        case .CF: "Centre Forward"
        case .ST: "Striker"
        }
    }

    var category: PositionCategory {
        switch self {
        case .GK: .goalkeeper
        case .RB, .LB, .CB: .defender
        case .DM, .RM, .LM, .CM: .midfielder
        case .RW, .LW, .AM, .CF, .ST: .attacker
        }
    }
}

nonisolated enum PositionCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case goalkeeper = "GK"
    case defender = "DEF"
    case midfielder = "MID"
    case attacker = "ATT"

    var color: String {
        switch self {
        case .goalkeeper: "#FFC107"
        case .defender: "#3B82F6"
        case .midfielder: "#4CAF50"
        case .attacker: "#EF4444"
        }
    }
}

nonisolated enum SquadStatus: String, Codable, Sendable, CaseIterable, Hashable {
    case keyPlayer = "Key Player"
    case firstTeam = "First Team"
    case rotation = "Rotation"
    case backup = "Backup"
    case youngster = "Youngster"
    case notNeeded = "Not Needed"
}

nonisolated struct SeasonStats: Codable, Sendable, Hashable {
    var appearances: Int = 0
    var goals: Int = 0
    var assists: Int = 0
    var yellowCards: Int = 0
    var redCards: Int = 0
    var avgRating: Double = 0.0
}

struct Player: Identifiable, Codable, Sendable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var age: Int
    var nationality: String
    var nationalityFlag: String
    var primaryPosition: PlayerPosition
    var secondaryPositions: [PlayerPosition]
    var style: String?
    var attributes: PlayerAttributes
    var overallRating: Int
    var morale: Int
    var currentFitness: Int
    var form: Int
    var contractExpiry: Int
    var weeklyWage: Int
    var squadStatus: SquadStatus
    var isInjured: Bool
    var injuryDescription: String?
    var injuryWeeksRemaining: Int?
    var isSuspended: Bool
    var suspensionWeeksRemaining: Int?
    var seasonStats: SeasonStats
    var marketValue: Int
    var isOnLoan: Bool

    var fullName: String { "\(firstName) \(lastName)" }
    var shortName: String {
        let firstInitial = firstName.prefix(1)
        return "\(firstInitial). \(lastName)"
    }

    static func computeOverall(for attributes: PlayerAttributes, position: PlayerPosition) -> Int {
        switch position.category {
        case .goalkeeper:
            let gk = attributes.goalkeepingAverage * 0.6
            let phys = attributes.physicalAverage * 0.2
            let mental = attributes.mentalAverage * 0.2
            return Int(gk + phys + mental)
        case .defender:
            let tech = attributes.technicalAverage * 0.2
            let phys = attributes.physicalAverage * 0.3
            let mental = attributes.mentalAverage * 0.3
            let def = Double(attributes.tackling + attributes.marking + attributes.heading) / 3.0 * 0.2
            return Int(tech + phys + mental + def)
        case .midfielder:
            let tech = attributes.technicalAverage * 0.35
            let phys = attributes.physicalAverage * 0.2
            let mental = attributes.mentalAverage * 0.3
            let mid = Double(attributes.passing + attributes.creativity + attributes.decisions) / 3.0 * 0.15
            return Int(tech + phys + mental + mid)
        case .attacker:
            let tech = attributes.technicalAverage * 0.35
            let phys = attributes.physicalAverage * 0.25
            let mental = attributes.mentalAverage * 0.2
            let att = Double(attributes.finishing + attributes.dribbling + attributes.pace) / 3.0 * 0.2
            return Int(tech + phys + mental + att)
        }
    }
}
