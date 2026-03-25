import Foundation

nonisolated struct FormationSlot: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let position: PlayerPosition
    let xPercent: Double
    let yPercent: Double
    var assignedPlayerID: String?
}

nonisolated struct Formation: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let name: String
    var slots: [FormationSlot]

    static let allFormations: [Formation] = [
        Formation.create("4-4-2", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.85, 0.75), (.CB, 0.65, 0.78), (.CB, 0.35, 0.78), (.LB, 0.15, 0.75),
            (.RM, 0.85, 0.50), (.CM, 0.65, 0.52), (.CM, 0.35, 0.52), (.LM, 0.15, 0.50),
            (.ST, 0.65, 0.22), (.ST, 0.35, 0.22)
        ]),
        Formation.create("4-3-3", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.85, 0.75), (.CB, 0.65, 0.78), (.CB, 0.35, 0.78), (.LB, 0.15, 0.75),
            (.CM, 0.7, 0.52), (.CM, 0.5, 0.55), (.CM, 0.3, 0.52),
            (.RW, 0.82, 0.28), (.ST, 0.5, 0.20), (.LW, 0.18, 0.28)
        ]),
        Formation.create("4-2-3-1", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.85, 0.75), (.CB, 0.65, 0.78), (.CB, 0.35, 0.78), (.LB, 0.15, 0.75),
            (.DM, 0.62, 0.58), (.DM, 0.38, 0.58),
            (.RW, 0.82, 0.38), (.AM, 0.5, 0.38), (.LW, 0.18, 0.38),
            (.ST, 0.5, 0.18)
        ]),
        Formation.create("3-5-2", positions: [
            (.GK, 0.5, 0.92),
            (.CB, 0.75, 0.78), (.CB, 0.5, 0.80), (.CB, 0.25, 0.78),
            (.RM, 0.88, 0.52), (.CM, 0.65, 0.52), (.CM, 0.5, 0.55), (.CM, 0.35, 0.52), (.LM, 0.12, 0.52),
            (.ST, 0.62, 0.22), (.ST, 0.38, 0.22)
        ]),
        Formation.create("4-1-4-1", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.85, 0.75), (.CB, 0.65, 0.78), (.CB, 0.35, 0.78), (.LB, 0.15, 0.75),
            (.DM, 0.5, 0.60),
            (.RM, 0.85, 0.42), (.CM, 0.62, 0.42), (.CM, 0.38, 0.42), (.LM, 0.15, 0.42),
            (.ST, 0.5, 0.18)
        ]),
        Formation.create("3-4-3", positions: [
            (.GK, 0.5, 0.92),
            (.CB, 0.75, 0.78), (.CB, 0.5, 0.80), (.CB, 0.25, 0.78),
            (.RM, 0.85, 0.52), (.CM, 0.62, 0.55), (.CM, 0.38, 0.55), (.LM, 0.15, 0.52),
            (.RW, 0.78, 0.25), (.ST, 0.5, 0.20), (.LW, 0.22, 0.25)
        ]),
        Formation.create("4-4-1-1", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.85, 0.75), (.CB, 0.65, 0.78), (.CB, 0.35, 0.78), (.LB, 0.15, 0.75),
            (.RM, 0.85, 0.52), (.CM, 0.62, 0.55), (.CM, 0.38, 0.55), (.LM, 0.15, 0.52),
            (.AM, 0.5, 0.35),
            (.ST, 0.5, 0.18)
        ]),
        Formation.create("5-3-2", positions: [
            (.GK, 0.5, 0.92),
            (.RB, 0.9, 0.70), (.CB, 0.7, 0.78), (.CB, 0.5, 0.80), (.CB, 0.3, 0.78), (.LB, 0.1, 0.70),
            (.CM, 0.7, 0.50), (.CM, 0.5, 0.52), (.CM, 0.3, 0.50),
            (.ST, 0.62, 0.22), (.ST, 0.38, 0.22)
        ]),
    ]

    private static func create(_ name: String, positions: [(PlayerPosition, Double, Double)]) -> Formation {
        let slots = positions.enumerated().map { index, pos in
            FormationSlot(id: "\(name)-\(index)", position: pos.0, xPercent: pos.1, yPercent: pos.2)
        }
        return Formation(id: name, name: name, slots: slots)
    }
}
