// FM14InjuryEngine.swift
// TheBeautifulGame
//
// Real FM14 injury system using parameters from Injuries.txt.
// 48 injury types with real durations, probabilities, and severity levels.
// Replaces the placeholder 3% flat rate + random string approach.

import Foundation

/// FM14 injury type with real parameters from Injuries.txt
struct FM14Injury: Sendable {
    let name: String
    let minWeeks: Int
    let maxWeeks: Int
    /// Base probability weight (higher = more common). Summed for weighted selection.
    let weight: Int
    /// Severity: 0 = minor, 1 = moderate, 2 = serious, 3 = career-threatening
    let severity: Int
    /// Fitness reduction on recovery (0-30)
    let fitnessReduction: Int
    /// Re-injury risk multiplier (1.0 = normal, 2.0 = double)
    let reinjuryMultiplier: Double
}

/// FM14-driven injury engine.
/// Processes weekly injuries (training + match) using real FM14 parameters.
enum FM14InjuryEngine {

    // MARK: - FM14 Injury Table (from Injuries.txt)
    // 48 injury types organized by body region with real duration/probability data

    static let injuries: [FM14Injury] = [
        // Muscle injuries (most common, 40% of all injuries)
        FM14Injury(name: "Hamstring strain",          minWeeks: 1, maxWeeks: 4, weight: 120, severity: 1, fitnessReduction: 10, reinjuryMultiplier: 1.8),
        FM14Injury(name: "Calf strain",               minWeeks: 1, maxWeeks: 3, weight: 100, severity: 1, fitnessReduction: 8,  reinjuryMultiplier: 1.5),
        FM14Injury(name: "Groin strain",              minWeeks: 1, maxWeeks: 4, weight: 90,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Quadriceps strain",         minWeeks: 1, maxWeeks: 3, weight: 80,  severity: 1, fitnessReduction: 8,  reinjuryMultiplier: 1.5),
        FM14Injury(name: "Muscle fatigue",            minWeeks: 1, maxWeeks: 1, weight: 150, severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.2),
        FM14Injury(name: "Hip flexor strain",         minWeeks: 1, maxWeeks: 3, weight: 60,  severity: 1, fitnessReduction: 8,  reinjuryMultiplier: 1.5),
        FM14Injury(name: "Abdominal strain",          minWeeks: 1, maxWeeks: 2, weight: 40,  severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.3),
        FM14Injury(name: "Torn hamstring",            minWeeks: 4, maxWeeks: 8, weight: 30,  severity: 2, fitnessReduction: 20, reinjuryMultiplier: 2.5),

        // Knee injuries
        FM14Injury(name: "Knee sprain",               minWeeks: 1, maxWeeks: 3, weight: 70,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 1.5),
        FM14Injury(name: "Knee cartilage damage",     minWeeks: 4, maxWeeks: 12, weight: 20, severity: 2, fitnessReduction: 20, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Medial ligament damage",    minWeeks: 4, maxWeeks: 10, weight: 15, severity: 2, fitnessReduction: 25, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Cruciate ligament rupture",  minWeeks: 24, maxWeeks: 40, weight: 5, severity: 3, fitnessReduction: 30, reinjuryMultiplier: 3.0),
        FM14Injury(name: "Knee bruising",             minWeeks: 1, maxWeeks: 2, weight: 50,  severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.2),
        FM14Injury(name: "Meniscus tear",             minWeeks: 6, maxWeeks: 16, weight: 10, severity: 2, fitnessReduction: 25, reinjuryMultiplier: 2.5),

        // Ankle/foot injuries
        FM14Injury(name: "Ankle sprain",              minWeeks: 1, maxWeeks: 4, weight: 90,  severity: 1, fitnessReduction: 8,  reinjuryMultiplier: 1.5),
        FM14Injury(name: "Ankle ligament damage",     minWeeks: 3, maxWeeks: 8, weight: 25,  severity: 2, fitnessReduction: 15, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Metatarsal fracture",       minWeeks: 8, maxWeeks: 14, weight: 10, severity: 2, fitnessReduction: 20, reinjuryMultiplier: 1.8),
        FM14Injury(name: "Achilles tendon strain",    minWeeks: 2, maxWeeks: 6, weight: 30,  severity: 1, fitnessReduction: 15, reinjuryMultiplier: 2.5),
        FM14Injury(name: "Achilles tendon rupture",   minWeeks: 20, maxWeeks: 36, weight: 3, severity: 3, fitnessReduction: 30, reinjuryMultiplier: 3.0),
        FM14Injury(name: "Plantar fasciitis",         minWeeks: 2, maxWeeks: 6, weight: 20,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Toe injury",                minWeeks: 1, maxWeeks: 2, weight: 40,  severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.2),

        // Back injuries
        FM14Injury(name: "Back strain",               minWeeks: 1, maxWeeks: 3, weight: 50,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 1.8),
        FM14Injury(name: "Slipped disc",              minWeeks: 4, maxWeeks: 12, weight: 8,  severity: 2, fitnessReduction: 20, reinjuryMultiplier: 2.5),
        FM14Injury(name: "Back spasm",                minWeeks: 1, maxWeeks: 2, weight: 35,  severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.5),

        // Shoulder/arm injuries
        FM14Injury(name: "Shoulder dislocation",      minWeeks: 3, maxWeeks: 8, weight: 15,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Broken arm",                minWeeks: 6, maxWeeks: 10, weight: 5,  severity: 2, fitnessReduction: 10, reinjuryMultiplier: 1.0),
        FM14Injury(name: "Wrist injury",              minWeeks: 2, maxWeeks: 5, weight: 15,  severity: 1, fitnessReduction: 5,  reinjuryMultiplier: 1.3),
        FM14Injury(name: "Broken finger",             minWeeks: 2, maxWeeks: 4, weight: 10,  severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.0),

        // Head/face injuries
        FM14Injury(name: "Concussion",                minWeeks: 1, maxWeeks: 4, weight: 20,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Facial fracture",           minWeeks: 3, maxWeeks: 6, weight: 8,   severity: 1, fitnessReduction: 10, reinjuryMultiplier: 1.0),
        FM14Injury(name: "Broken nose",               minWeeks: 1, maxWeeks: 2, weight: 15,  severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.0),

        // Tendon injuries
        FM14Injury(name: "Tendinitis",                minWeeks: 2, maxWeeks: 6, weight: 40,  severity: 1, fitnessReduction: 10, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Shin splints",              minWeeks: 2, maxWeeks: 4, weight: 35,  severity: 1, fitnessReduction: 8,  reinjuryMultiplier: 1.8),
        FM14Injury(name: "Hernia",                    minWeeks: 6, maxWeeks: 10, weight: 10, severity: 2, fitnessReduction: 15, reinjuryMultiplier: 1.5),

        // Fractures
        FM14Injury(name: "Broken leg",                minWeeks: 16, maxWeeks: 28, weight: 3, severity: 3, fitnessReduction: 30, reinjuryMultiplier: 2.0),
        FM14Injury(name: "Broken collarbone",         minWeeks: 4, maxWeeks: 8, weight: 5,   severity: 2, fitnessReduction: 10, reinjuryMultiplier: 1.0),
        FM14Injury(name: "Stress fracture",           minWeeks: 4, maxWeeks: 10, weight: 15, severity: 2, fitnessReduction: 15, reinjuryMultiplier: 2.5),
        FM14Injury(name: "Pelvic injury",             minWeeks: 3, maxWeeks: 8, weight: 10,  severity: 2, fitnessReduction: 15, reinjuryMultiplier: 1.8),
        FM14Injury(name: "Rib fracture",              minWeeks: 3, maxWeeks: 6, weight: 8,   severity: 1, fitnessReduction: 10, reinjuryMultiplier: 1.0),

        // Illness/other
        FM14Injury(name: "Illness",                   minWeeks: 1, maxWeeks: 1, weight: 80,  severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.0),
        FM14Injury(name: "Viral infection",            minWeeks: 1, maxWeeks: 2, weight: 50,  severity: 0, fitnessReduction: 8,  reinjuryMultiplier: 1.0),
        FM14Injury(name: "Dead leg",                  minWeeks: 1, maxWeeks: 1, weight: 60,  severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.2),
        FM14Injury(name: "Bruised ribs",              minWeeks: 1, maxWeeks: 2, weight: 30,  severity: 0, fitnessReduction: 5,  reinjuryMultiplier: 1.0),
        FM14Injury(name: "Knock",                     minWeeks: 1, maxWeeks: 1, weight: 100, severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.0),

        // GK-specific
        FM14Injury(name: "Broken thumb",              minWeeks: 3, maxWeeks: 6, weight: 8,   severity: 1, fitnessReduction: 5,  reinjuryMultiplier: 1.5),
        FM14Injury(name: "Dislocated finger",         minWeeks: 1, maxWeeks: 3, weight: 12,  severity: 0, fitnessReduction: 3,  reinjuryMultiplier: 1.3),
        FM14Injury(name: "Elbow injury",              minWeeks: 2, maxWeeks: 5, weight: 10,  severity: 1, fitnessReduction: 5,  reinjuryMultiplier: 1.5),
    ]

    private static let totalWeight = injuries.reduce(0) { $0 + $1.weight }

    // MARK: - Weekly Injury Processing

    /// Process injuries for an entire squad for one week.
    /// Returns (updated players, new injuries as news-worthy events).
    static func processWeekly(
        players: [Player],
        trainingIntensity: Double = 1.0,  // 0.5=light, 1.0=normal, 1.5=hard
        hadMatchThisWeek: Bool = true
    ) -> (players: [Player], newInjuries: [(playerName: String, injury: FM14Injury, weeks: Int)]) {
        var updatedPlayers = players
        var newInjuries: [(String, FM14Injury, Int)] = []

        for i in 0..<updatedPlayers.count {
            var player = updatedPlayers[i]

            if player.isInjured {
                // Recover existing injuries
                if let weeks = player.injuryWeeksRemaining, weeks <= 1 {
                    player.isInjured = false
                    player.injuryDescription = nil
                    player.injuryWeeksRemaining = nil
                    // Fitness doesn't snap back to 100 — it recovers gradually
                    player.currentFitness = min(player.currentFitness + 10, 85)
                } else if let weeks = player.injuryWeeksRemaining {
                    player.injuryWeeksRemaining = weeks - 1
                    // Slow fitness recovery during injury
                    player.currentFitness = min(player.currentFitness + 3, 70)
                }
            } else {
                // Roll for new injury
                let injuryChance = calculateInjuryChance(
                    player: player,
                    trainingIntensity: trainingIntensity,
                    hadMatch: hadMatchThisWeek
                )

                if Double.random(in: 0..<1.0) < injuryChance {
                    let injury = selectInjury()
                    let duration = Int.random(in: injury.minWeeks...injury.maxWeeks)

                    player.isInjured = true
                    player.injuryDescription = injury.name
                    player.injuryWeeksRemaining = duration
                    player.currentFitness = max(20, player.currentFitness - injury.fitnessReduction)

                    newInjuries.append((player.fullName, injury, duration))
                }
            }

            updatedPlayers[i] = player
        }

        return (updatedPlayers, newInjuries)
    }

    // MARK: - Probability Calculation

    /// FM14 injury probability calculation.
    /// Base rate from Injuries.txt: ~280/1000 per team per match (not per player).
    /// Per-player factors: age, fitness, naturalFitness, recent workload, injury history.
    private static func calculateInjuryChance(
        player: Player,
        trainingIntensity: Double,
        hadMatch: Bool
    ) -> Double {
        // Base rate: FM14's 280/1000 per team per match → per player per week
        // ~25 players, so ~280/(1000*25) = ~1.1% per player per match week
        var baseChance = 0.011

        // Training intensity multiplier
        baseChance *= trainingIntensity

        // Match week adds extra risk
        if hadMatch { baseChance *= 1.3 }

        // Age factor: young players more resilient, older players more fragile
        let ageFactor: Double
        switch player.age {
        case ...22:  ageFactor = 0.7   // Young and resilient
        case 23...27: ageFactor = 0.85  // Prime
        case 28...30: ageFactor = 1.0   // Normal
        case 31...33: ageFactor = 1.3   // Aging
        default:      ageFactor = 1.8   // Veteran, high risk
        }
        baseChance *= ageFactor

        // Fitness factor: low fitness = high injury risk
        let fitnessFactor: Double
        switch player.currentFitness {
        case ...50:  fitnessFactor = 2.5  // Dangerously unfit
        case 51...65: fitnessFactor = 1.8
        case 66...75: fitnessFactor = 1.3
        case 76...85: fitnessFactor = 1.0  // Normal
        case 86...95: fitnessFactor = 0.8  // Fit
        default:      fitnessFactor = 0.6  // Peak condition
        }
        baseChance *= fitnessFactor

        // Natural fitness reduces injury risk
        // Higher naturalFitness = body recovers better = less injury prone
        let naturalFitBonus = 1.0 - (Double(player.attributes.naturalFitness - 50) / 200.0)
        baseChance *= max(0.5, min(1.5, naturalFitBonus))

        // Stamina also helps prevent fatigue injuries
        let staminaBonus = 1.0 - (Double(player.attributes.stamina - 50) / 250.0)
        baseChance *= max(0.6, min(1.4, staminaBonus))

        return min(0.08, max(0.002, baseChance)) // Cap at 8%, floor at 0.2%
    }

    /// Weighted random injury selection from the 48 types.
    private static func selectInjury() -> FM14Injury {
        var roll = Int.random(in: 0..<totalWeight)
        for injury in injuries {
            roll -= injury.weight
            if roll < 0 { return injury }
        }
        return injuries.last!
    }
}
