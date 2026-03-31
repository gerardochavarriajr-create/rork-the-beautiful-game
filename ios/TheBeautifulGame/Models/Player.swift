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
    var naturalFitness: Int

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

    init(
        ballControl: Int, crossing: Int, dribbling: Int, finishing: Int, heading: Int,
        longShots: Int, marking: Int, passing: Int, setPieces: Int, shotPower: Int,
        tackling: Int, technique: Int, throwing: Int,
        acceleration: Int, agility: Int, balance: Int, jumping: Int, pace: Int,
        stamina: Int, strength: Int, fitness: Int, naturalFitness: Int,
        aggression: Int, anticipation: Int, composure: Int, concentration: Int,
        creativity: Int, decisions: Int, determination: Int, flair: Int,
        leadership: Int, positioning: Int, workRate: Int,
        aerialAbility: Int, commandOfArea: Int, communication: Int,
        handling: Int, kicking: Int, oneOnOnes: Int, reflexes: Int, rushingOut: Int
    ) {
        self.ballControl = ballControl; self.crossing = crossing; self.dribbling = dribbling
        self.finishing = finishing; self.heading = heading; self.longShots = longShots
        self.marking = marking; self.passing = passing; self.setPieces = setPieces
        self.shotPower = shotPower; self.tackling = tackling; self.technique = technique
        self.throwing = throwing
        self.acceleration = acceleration; self.agility = agility; self.balance = balance
        self.jumping = jumping; self.pace = pace; self.stamina = stamina
        self.strength = strength; self.fitness = fitness; self.naturalFitness = naturalFitness
        self.aggression = aggression; self.anticipation = anticipation; self.composure = composure
        self.concentration = concentration; self.creativity = creativity; self.decisions = decisions
        self.determination = determination; self.flair = flair; self.leadership = leadership
        self.positioning = positioning; self.workRate = workRate
        self.aerialAbility = aerialAbility; self.commandOfArea = commandOfArea
        self.communication = communication; self.handling = handling; self.kicking = kicking
        self.oneOnOnes = oneOnOnes; self.reflexes = reflexes; self.rushingOut = rushingOut
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ballControl = try c.decode(Int.self, forKey: .ballControl)
        crossing = try c.decode(Int.self, forKey: .crossing)
        dribbling = try c.decode(Int.self, forKey: .dribbling)
        finishing = try c.decode(Int.self, forKey: .finishing)
        heading = try c.decode(Int.self, forKey: .heading)
        longShots = try c.decode(Int.self, forKey: .longShots)
        marking = try c.decode(Int.self, forKey: .marking)
        passing = try c.decode(Int.self, forKey: .passing)
        setPieces = try c.decode(Int.self, forKey: .setPieces)
        shotPower = try c.decode(Int.self, forKey: .shotPower)
        tackling = try c.decode(Int.self, forKey: .tackling)
        technique = try c.decode(Int.self, forKey: .technique)
        throwing = try c.decode(Int.self, forKey: .throwing)
        acceleration = try c.decode(Int.self, forKey: .acceleration)
        agility = try c.decode(Int.self, forKey: .agility)
        balance = try c.decode(Int.self, forKey: .balance)
        jumping = try c.decode(Int.self, forKey: .jumping)
        pace = try c.decode(Int.self, forKey: .pace)
        stamina = try c.decode(Int.self, forKey: .stamina)
        strength = try c.decode(Int.self, forKey: .strength)
        fitness = try c.decode(Int.self, forKey: .fitness)
        naturalFitness = try c.decodeIfPresent(Int.self, forKey: .naturalFitness) ?? fitness
        aggression = try c.decode(Int.self, forKey: .aggression)
        anticipation = try c.decode(Int.self, forKey: .anticipation)
        composure = try c.decode(Int.self, forKey: .composure)
        concentration = try c.decode(Int.self, forKey: .concentration)
        creativity = try c.decode(Int.self, forKey: .creativity)
        decisions = try c.decode(Int.self, forKey: .decisions)
        determination = try c.decode(Int.self, forKey: .determination)
        flair = try c.decode(Int.self, forKey: .flair)
        leadership = try c.decode(Int.self, forKey: .leadership)
        positioning = try c.decode(Int.self, forKey: .positioning)
        workRate = try c.decode(Int.self, forKey: .workRate)
        aerialAbility = try c.decode(Int.self, forKey: .aerialAbility)
        commandOfArea = try c.decode(Int.self, forKey: .commandOfArea)
        communication = try c.decode(Int.self, forKey: .communication)
        handling = try c.decode(Int.self, forKey: .handling)
        kicking = try c.decode(Int.self, forKey: .kicking)
        oneOnOnes = try c.decode(Int.self, forKey: .oneOnOnes)
        reflexes = try c.decode(Int.self, forKey: .reflexes)
        rushingOut = try c.decode(Int.self, forKey: .rushingOut)
    }

    var technicalAverage: Double {
        let vals = [ballControl, crossing, dribbling, finishing, heading, longShots, marking, passing, setPieces, shotPower, tackling, technique, throwing]
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var physicalAverage: Double {
        let vals = [acceleration, agility, balance, jumping, pace, stamina, strength, fitness, naturalFitness]
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
