// FM14TrainingEngine.swift
// TheBeautifulGame
//
// Real FM14 training system using parameters from Training.txt and Training Sessions.txt.
// 7 training focus types with attribute-specific multipliers.
// Replaces the placeholder random ±1-2 fitness change with real attribute growth.

import Foundation

/// Training type focus areas (from FM14's Training.txt).
/// Each type has a set of attributes it improves and multipliers for how fast they grow.
enum TrainingFocus: String, Codable, Sendable, CaseIterable {
    case technical    // Ball control, dribbling, technique, passing
    case attacking    // Finishing, shot power, long shots, heading
    case defending    // Tackling, marking, positioning, heading
    case physical     // Pace, acceleration, strength, stamina, agility
    case setPieces    // Set pieces, crossing, technique
    case tactical     // Anticipation, decisions, composure, concentration, work rate, positioning
    case rest         // Recovery — no training, fitness recovers faster
}

/// Attribute multiplier for a training type.
/// FM14 uses multipliers 0.0-2.0 per attribute per session type.
private struct TrainingMultiplier {
    let focus: TrainingFocus
    /// Maps attribute keypath name → multiplier (0.0 = no effect, 2.0 = double growth)
    let multipliers: [String: Double]
}

/// FM14-driven training engine.
/// Applies weekly training effects based on the selected focus for each day.
enum FM14TrainingEngine {

    // MARK: - FM14 Training Multipliers (from Training.txt / Training Sessions.txt)

    /// How much each attribute can change per training week.
    /// FM14 base growth: ~0.3-0.5 attribute points per week for focused attributes.
    /// Modified by: age, talent, naturalFitness, training type multiplier.
    private static let baseGrowthPerWeek: Double = 0.35

    /// FM14 training multipliers by focus type.
    /// Key = attribute name, Value = multiplier (0 = no effect, 1 = normal, 2 = strong focus).
    private static let trainingEffects: [TrainingFocus: [String: Double]] = [
        .technical: [
            "ballControl": 1.8, "dribbling": 1.5, "technique": 1.8, "passing": 1.5,
            "crossing": 1.0, "setPieces": 0.5, "longShots": 0.3,
            // Minor physical maintenance
            "stamina": 0.2, "fitness": 0.3,
        ],
        .attacking: [
            "finishing": 2.0, "shotPower": 1.5, "longShots": 1.5, "heading": 1.0,
            "dribbling": 0.8, "composure": 0.5, "anticipation": 0.5,
            "stamina": 0.2, "fitness": 0.3,
        ],
        .defending: [
            "tackling": 2.0, "marking": 1.8, "positioning": 1.5, "heading": 1.0,
            "strength": 0.5, "aggression": 0.3, "concentration": 0.8,
            "stamina": 0.3, "fitness": 0.3,
        ],
        .physical: [
            "pace": 1.0, "acceleration": 1.0, "strength": 1.5, "stamina": 2.0,
            "agility": 1.0, "jumping": 0.8, "balance": 0.5,
            "fitness": 1.5, "naturalFitness": 0.3,
        ],
        .setPieces: [
            "setPieces": 2.0, "crossing": 1.5, "technique": 1.0, "longShots": 0.8,
            "passing": 0.5, "finishing": 0.3,
            "stamina": 0.1, "fitness": 0.2,
        ],
        .tactical: [
            "anticipation": 1.8, "decisions": 1.8, "composure": 1.5, "concentration": 1.5,
            "workRate": 1.0, "positioning": 1.0, "leadership": 0.5, "creativity": 0.8,
            "stamina": 0.2, "fitness": 0.3,
        ],
        .rest: [
            // Rest day: only fitness recovery, no skill training
            "fitness": 2.0, "naturalFitness": 0.1,
        ],
    ]

    // MARK: - Weekly Training Application

    /// Apply a full week of training to a squad.
    /// `weeklySchedule` has 7 entries (Mon-Sun), one TrainingFocus per day.
    static func applyWeeklyTraining(
        players: [Player],
        weeklySchedule: [TrainingType],
        teamPrestige: Int = 5
    ) -> [Player] {
        // Count focus days per type
        let focusCounts = countFocusDays(schedule: weeklySchedule)

        return players.map { player in
            guard !player.isInjured else {
                // Injured players don't train but lose fitness slowly
                var p = player
                p.currentFitness = max(30, p.currentFitness - 2)
                return p
            }
            return applyTraining(to: player, focusCounts: focusCounts, teamPrestige: teamPrestige)
        }
    }

    // MARK: - Per-Player Training

    private static func applyTraining(
        to player: Player,
        focusCounts: [TrainingFocus: Int],
        teamPrestige: Int
    ) -> Player {
        var attrs = player.attributes

        // Age modifier: young players develop faster, older decline
        let ageModifier = ageGrowthModifier(age: player.age)

        // Talent modifier (not yet in model — use prestige as proxy)
        let talentModifier = 0.8 + Double(teamPrestige) * 0.04 // 1.0-1.2 for prestige 5-10

        // Natural fitness affects training effectiveness
        let naturalFitMod = 0.7 + Double(player.attributes.naturalFitness) * 0.006 // 0.7-1.3

        // Apply each training focus day's effects
        for (focus, dayCount) in focusCounts {
            guard let effects = trainingEffects[focus] else { continue }
            let intensity = Double(dayCount) / 7.0 // Fraction of week spent on this

            for (attrName, multiplier) in effects {
                let growth = baseGrowthPerWeek * multiplier * intensity * ageModifier * talentModifier * naturalFitMod
                // Add some randomness (±30%)
                let actualGrowth = growth * Double.random(in: 0.7...1.3)

                applyGrowth(to: &attrs, attribute: attrName, amount: actualGrowth)
            }
        }

        // Age-based decline for older players (30+)
        if player.age >= 30 {
            applyDecline(to: &attrs, age: player.age)
        }

        // Update fitness based on training load
        let restDays = focusCounts[.rest] ?? 0
        let trainingLoad = 7 - restDays
        let fitnessChange = restDays * 3 - trainingLoad // More rest = more fitness recovery
        attrs.fitness = clamp(attrs.fitness + fitnessChange, min: 30, max: 99)

        var updatedPlayer = player
        updatedPlayer.attributes = attrs
        updatedPlayer.currentFitness = attrs.fitness
        // Recalculate overall after training
        updatedPlayer.overallRating = Player.computeOverall(for: attrs, position: player.primaryPosition)

        return updatedPlayer
    }

    // MARK: - Growth Helpers

    /// FM14 age growth curve from Player Development.txt
    private static func ageGrowthModifier(age: Int) -> Double {
        switch age {
        case ...17:  return 1.5   // Youth — rapid development
        case 18:     return 1.4
        case 19:     return 1.3
        case 20:     return 1.2
        case 21:     return 1.1
        case 22...24: return 1.0  // Early prime — normal growth
        case 25...27: return 0.8  // Prime — slower growth, peak performance
        case 28...29: return 0.5  // Late prime — minimal growth
        case 30...31: return 0.2  // Decline phase — very slow
        case 32...33: return 0.0  // Maintenance only
        default:      return -0.2 // 34+ — physical decline begins
        }
    }

    /// Apply gradual physical decline for aging players
    private static func applyDecline(to attrs: inout PlayerAttributes, age: Int) {
        let declineRate: Double
        switch age {
        case 30...31: declineRate = 0.05
        case 32...33: declineRate = 0.12
        case 34...35: declineRate = 0.20
        default:      declineRate = 0.30  // 36+
        }

        // Physical attributes decline; mental attributes can still grow
        let physicals = ["pace", "acceleration", "stamina", "agility", "jumping", "strength"]
        for attr in physicals {
            if Double.random(in: 0..<1.0) < declineRate {
                applyGrowth(to: &attrs, attribute: attr, amount: -Double.random(in: 0.3...0.8))
            }
        }
    }

    /// Apply a growth/decline amount to a named attribute
    private static func applyGrowth(to attrs: inout PlayerAttributes, attribute: String, amount: Double) {
        // Only apply if the change rounds to at least ±1, or accumulate fractionally
        let rounded = Int(amount.rounded())
        guard rounded != 0 || abs(amount) > 0.3 else { return }
        let change = rounded != 0 ? rounded : (amount > 0 ? 1 : -1)

        switch attribute {
        // Technical
        case "ballControl":   attrs.ballControl   = clamp(attrs.ballControl + change, min: 1, max: 99)
        case "crossing":      attrs.crossing      = clamp(attrs.crossing + change, min: 1, max: 99)
        case "dribbling":     attrs.dribbling     = clamp(attrs.dribbling + change, min: 1, max: 99)
        case "finishing":     attrs.finishing      = clamp(attrs.finishing + change, min: 1, max: 99)
        case "heading":       attrs.heading        = clamp(attrs.heading + change, min: 1, max: 99)
        case "longShots":     attrs.longShots      = clamp(attrs.longShots + change, min: 1, max: 99)
        case "marking":       attrs.marking        = clamp(attrs.marking + change, min: 1, max: 99)
        case "passing":       attrs.passing        = clamp(attrs.passing + change, min: 1, max: 99)
        case "setPieces":     attrs.setPieces      = clamp(attrs.setPieces + change, min: 1, max: 99)
        case "shotPower":     attrs.shotPower      = clamp(attrs.shotPower + change, min: 1, max: 99)
        case "tackling":      attrs.tackling       = clamp(attrs.tackling + change, min: 1, max: 99)
        case "technique":     attrs.technique      = clamp(attrs.technique + change, min: 1, max: 99)
        case "throwing":      attrs.throwing       = clamp(attrs.throwing + change, min: 1, max: 99)
        // Physical
        case "acceleration":  attrs.acceleration   = clamp(attrs.acceleration + change, min: 1, max: 99)
        case "agility":       attrs.agility        = clamp(attrs.agility + change, min: 1, max: 99)
        case "balance":       attrs.balance        = clamp(attrs.balance + change, min: 1, max: 99)
        case "jumping":       attrs.jumping        = clamp(attrs.jumping + change, min: 1, max: 99)
        case "pace":          attrs.pace           = clamp(attrs.pace + change, min: 1, max: 99)
        case "stamina":       attrs.stamina        = clamp(attrs.stamina + change, min: 1, max: 99)
        case "strength":      attrs.strength       = clamp(attrs.strength + change, min: 1, max: 99)
        case "fitness":       attrs.fitness        = clamp(attrs.fitness + change, min: 1, max: 99)
        case "naturalFitness": attrs.naturalFitness = clamp(attrs.naturalFitness + change, min: 1, max: 99)
        // Mental
        case "aggression":    attrs.aggression     = clamp(attrs.aggression + change, min: 1, max: 99)
        case "anticipation":  attrs.anticipation   = clamp(attrs.anticipation + change, min: 1, max: 99)
        case "composure":     attrs.composure      = clamp(attrs.composure + change, min: 1, max: 99)
        case "concentration": attrs.concentration  = clamp(attrs.concentration + change, min: 1, max: 99)
        case "creativity":    attrs.creativity     = clamp(attrs.creativity + change, min: 1, max: 99)
        case "decisions":     attrs.decisions      = clamp(attrs.decisions + change, min: 1, max: 99)
        case "determination": attrs.determination  = clamp(attrs.determination + change, min: 1, max: 99)
        case "flair":         attrs.flair          = clamp(attrs.flair + change, min: 1, max: 99)
        case "leadership":    attrs.leadership     = clamp(attrs.leadership + change, min: 1, max: 99)
        case "positioning":   attrs.positioning    = clamp(attrs.positioning + change, min: 1, max: 99)
        case "workRate":      attrs.workRate       = clamp(attrs.workRate + change, min: 1, max: 99)
        // GK
        case "aerialAbility": attrs.aerialAbility  = clamp(attrs.aerialAbility + change, min: 1, max: 99)
        case "commandOfArea": attrs.commandOfArea  = clamp(attrs.commandOfArea + change, min: 1, max: 99)
        case "communication": attrs.communication  = clamp(attrs.communication + change, min: 1, max: 99)
        case "handling":      attrs.handling       = clamp(attrs.handling + change, min: 1, max: 99)
        case "kicking":       attrs.kicking        = clamp(attrs.kicking + change, min: 1, max: 99)
        case "oneOnOnes":     attrs.oneOnOnes      = clamp(attrs.oneOnOnes + change, min: 1, max: 99)
        case "reflexes":      attrs.reflexes       = clamp(attrs.reflexes + change, min: 1, max: 99)
        case "rushingOut":    attrs.rushingOut      = clamp(attrs.rushingOut + change, min: 1, max: 99)
        default: break
        }
    }

    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }

    /// Map Rork's TrainingType to FM14's TrainingFocus
    private static func countFocusDays(schedule: [TrainingType]) -> [TrainingFocus: Int] {
        var counts: [TrainingFocus: Int] = [:]
        for type in schedule {
            let focus = mapTrainingType(type)
            counts[focus, default: 0] += 1
        }
        return counts
    }

    private static func mapTrainingType(_ type: TrainingType) -> TrainingFocus {
        switch type {
        case .technical: return .technical
        case .attacking: return .attacking
        case .defending: return .defending
        case .physical: return .physical
        case .setPieces: return .setPieces
        case .rest: return .rest
        }
    }
}
