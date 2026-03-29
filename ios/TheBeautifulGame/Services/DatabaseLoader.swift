// DatabaseLoader.swift
// TheBeautifulGame
//
// Loads real player/club/league data from JSON files (output of parse_database.py).
// Replaces the procedural DatabaseGenerator with actual FM14/FM2026 mod data.
// Falls back to DatabaseGenerator if JSON files aren't bundled yet.

import Foundation

/// Loads pre-extracted FM14 database (players.json, clubs.json, leagues.json)
/// and maps them into Rork's existing model types (Player, Club, LeagueData).
enum DatabaseLoader {

    // MARK: - JSON Structures (match parse_database.py output)

    private struct RawPlayer: Codable {
        let id: String
        let firstName: String
        let lastName: String
        let age: Int
        let nationality: String
        let clubId: String
        let primaryPosition: Int       // 0-12 positional index
        let secondaryPositions: [Int]
        let attributes: RawAttributes
        let contractExpiry: Int
        let weeklyWage: Int
        let marketValue: Int
        let height: Int?
        let weight: Int?
        let preferredFoot: String?
    }

    private struct RawAttributes: Codable {
        let ballControl: Int
        let crossing: Int
        let dribbling: Int
        let finishing: Int
        let heading: Int
        let longShots: Int
        let marking: Int
        let passing: Int
        let setPieces: Int
        let shotPower: Int
        let tackling: Int
        let technique: Int
        let throwing: Int
        let acceleration: Int
        let agility: Int
        let balance: Int
        let jumping: Int
        let pace: Int
        let stamina: Int
        let strength: Int
        let fitness: Int
        let naturalFitness: Int
        let aggression: Int
        let anticipation: Int
        let composure: Int
        let concentration: Int
        let creativity: Int
        let decisions: Int
        let determination: Int
        let flair: Int
        let leadership: Int
        let positioning: Int
        let workRate: Int
        let aerialAbility: Int
        let commandOfArea: Int
        let communication: Int
        let handling: Int
        let kicking: Int
        let oneOnOnes: Int
        let reflexes: Int
        let rushingOut: Int
    }

    private struct RawClub: Codable {
        let id: String
        let name: String
        let shortName: String
        let city: String
        let stadium: String
        let stadiumCapacity: Int
        let league: String
        let leagueId: String
        let prestige: Int
        let primaryColor: String
        let secondaryColor: String
        let budget: Int
        let country: String
        let playerIds: [String]
    }

    private struct RawLeague: Codable {
        let id: String
        let name: String
        let country: String
        let teamCount: Int
    }

    // MARK: - Position Mapping (FM14 position index → our PlayerPosition)

    private static let positionMap: [Int: PlayerPosition] = [
        0: .GK,
        1: .RB,
        2: .LB,
        3: .CB,
        4: .DM,
        5: .RM,
        6: .LM,
        7: .CM,
        8: .RW,
        9: .LW,
        10: .AM,
        11: .CF,
        12: .ST
    ]

    private static let countryFlags: [String: String] = [
        "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Spain": "🇪🇸", "France": "🇫🇷", "Germany": "🇩🇪", "Italy": "🇮🇹",
        "Brazil": "🇧🇷", "Argentina": "🇦🇷", "Portugal": "🇵🇹", "Netherlands": "🇳🇱", "Belgium": "🇧🇪",
        "Croatia": "🇭🇷", "Poland": "🇵🇱", "Uruguay": "🇺🇾", "Colombia": "🇨🇴", "Senegal": "🇸🇳",
        "Egypt": "🇪🇬", "Morocco": "🇲🇦", "Nigeria": "🇳🇬", "Ivory Coast": "🇨🇮", "Ghana": "🇬🇭",
        "Cameroon": "🇨🇲", "Japan": "🇯🇵", "South Korea": "🇰🇷", "Australia": "🇦🇺",
        "USA": "🇺🇸", "Mexico": "🇲🇽", "Canada": "🇨🇦", "Chile": "🇨🇱", "Paraguay": "🇵🇾",
        "Ecuador": "🇪🇨", "Peru": "🇵🇪", "Venezuela": "🇻🇪", "Bolivia": "🇧🇴",
        "Norway": "🇳🇴", "Sweden": "🇸🇪", "Denmark": "🇩🇰", "Finland": "🇫🇮",
        "Switzerland": "🇨🇭", "Austria": "🇦🇹", "Czech Republic": "🇨🇿", "Serbia": "🇷🇸",
        "Turkey": "🇹🇷", "Wales": "🏴󠁧󠁢󠁷󠁬󠁳󠁿", "Scotland": "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
        "Ireland": "🇮🇪", "Northern Ireland": "🇬🇧", "Jamaica": "🇯🇲",
        "Romania": "🇷🇴", "Hungary": "🇭🇺", "Slovakia": "🇸🇰", "Ukraine": "🇺🇦",
        "Russia": "🇷🇺", "Greece": "🇬🇷", "Israel": "🇮🇱", "China": "🇨🇳",
        "Algeria": "🇩🇿", "Tunisia": "🇹🇳", "DR Congo": "🇨🇩", "Mali": "🇲🇱",
        "Guinea": "🇬🇳", "Gabon": "🇬🇦", "Burkina Faso": "🇧🇫"
    ]

    // MARK: - Public API

    /// Attempt to load real database from bundled JSON files.
    /// Returns nil if files aren't available (caller should fall back to DatabaseGenerator).
    static func loadLeagues() -> [LeagueInfo]? {
        guard let leagues = loadJSON([RawLeague].self, filename: "leagues") else { return nil }
        return leagues.map { raw in
            let flag = countryFlags[raw.country] ?? "🏳️"
            return LeagueInfo(id: raw.id, name: raw.name, country: raw.country, flagEmoji: flag, teamCount: raw.teamCount)
        }
    }

    /// Load full league data (clubs + players) for a specific league.
    /// Returns nil if JSON files aren't available.
    static func loadLeagueData(for leagueInfo: LeagueInfo) -> LeagueData? {
        guard let rawClubs = loadJSON([RawClub].self, filename: "clubs"),
              let rawPlayers = loadJSON([RawPlayer].self, filename: "players") else {
            return nil
        }

        // Filter clubs for this league
        let leagueClubs = rawClubs.filter { $0.leagueId == leagueInfo.id }
        guard !leagueClubs.isEmpty else { return nil }

        // Build player lookup by ID
        let playerLookup = Dictionary(uniqueKeysWithValues: rawPlayers.map { ($0.id, $0) })

        // Convert clubs with their players
        var clubs: [Club] = []
        for rawClub in leagueClubs {
            let clubPlayers = rawClub.playerIds.compactMap { playerLookup[$0] }.map { mapPlayer($0) }
            let club = mapClub(rawClub, players: clubPlayers)
            clubs.append(club)
        }

        let table = clubs.map { club in
            LeagueTableRow(teamName: club.name, isUserTeam: false)
        }
        let fixtures = generateFixtures(teams: clubs.map(\.name), competition: leagueInfo.name)

        return LeagueData(info: leagueInfo, table: table, fixtures: fixtures, clubs: clubs)
    }

    // MARK: - Mapping Functions

    private static func mapPlayer(_ raw: RawPlayer) -> Player {
        let position = positionMap[raw.primaryPosition] ?? .CM
        let secondaryPositions = raw.secondaryPositions.compactMap { positionMap[$0] }
        let flag = countryFlags[raw.nationality] ?? "🏳️"

        let attrs = PlayerAttributes(
            ballControl: raw.attributes.ballControl,
            crossing: raw.attributes.crossing,
            dribbling: raw.attributes.dribbling,
            finishing: raw.attributes.finishing,
            heading: raw.attributes.heading,
            longShots: raw.attributes.longShots,
            marking: raw.attributes.marking,
            passing: raw.attributes.passing,
            setPieces: raw.attributes.setPieces,
            shotPower: raw.attributes.shotPower,
            tackling: raw.attributes.tackling,
            technique: raw.attributes.technique,
            throwing: raw.attributes.throwing,
            acceleration: raw.attributes.acceleration,
            agility: raw.attributes.agility,
            balance: raw.attributes.balance,
            jumping: raw.attributes.jumping,
            pace: raw.attributes.pace,
            stamina: raw.attributes.stamina,
            strength: raw.attributes.strength,
            fitness: raw.attributes.fitness,
            naturalFitness: raw.attributes.naturalFitness,
            aggression: raw.attributes.aggression,
            anticipation: raw.attributes.anticipation,
            composure: raw.attributes.composure,
            concentration: raw.attributes.concentration,
            creativity: raw.attributes.creativity,
            decisions: raw.attributes.decisions,
            determination: raw.attributes.determination,
            flair: raw.attributes.flair,
            leadership: raw.attributes.leadership,
            positioning: raw.attributes.positioning,
            workRate: raw.attributes.workRate,
            aerialAbility: raw.attributes.aerialAbility,
            commandOfArea: raw.attributes.commandOfArea,
            communication: raw.attributes.communication,
            handling: raw.attributes.handling,
            kicking: raw.attributes.kicking,
            oneOnOnes: raw.attributes.oneOnOnes,
            reflexes: raw.attributes.reflexes,
            rushingOut: raw.attributes.rushingOut
        )

        let overall = Player.computeOverall(for: attrs, position: position)
        let squadStatus: SquadStatus
        switch overall {
        case 80...99: squadStatus = .keyPlayer
        case 72...79: squadStatus = .firstTeam
        case 65...71: squadStatus = .rotation
        case 55...64: squadStatus = .backup
        default: squadStatus = raw.age < 21 ? .youngster : .backup
        }

        return Player(
            id: raw.id,
            firstName: raw.firstName,
            lastName: raw.lastName,
            age: raw.age,
            nationality: raw.nationality,
            nationalityFlag: flag,
            primaryPosition: position,
            secondaryPositions: secondaryPositions,
            style: nil,
            attributes: attrs,
            overallRating: overall,
            morale: Int.random(in: 60...85),
            currentFitness: Int.random(in: 75...100),
            form: Int.random(in: 8...15),
            contractExpiry: raw.contractExpiry,
            weeklyWage: raw.weeklyWage,
            squadStatus: squadStatus,
            isInjured: false,
            injuryDescription: nil,
            injuryWeeksRemaining: nil,
            isSuspended: false,
            suspensionWeeksRemaining: nil,
            seasonStats: SeasonStats(),
            marketValue: raw.marketValue,
            isOnLoan: false
        )
    }

    private static func mapClub(_ raw: RawClub, players: [Player]) -> Club {
        Club(
            id: raw.id,
            name: raw.name,
            shortName: raw.shortName,
            city: raw.city,
            stadium: Stadium(name: raw.stadium, capacity: raw.stadiumCapacity),
            league: raw.league,
            prestige: raw.prestige,
            primaryColor: raw.primaryColor,
            secondaryColor: raw.secondaryColor,
            budget: ClubBudget(
                transfer: raw.budget,
                wage: raw.budget / 2,
                total: raw.budget + raw.budget / 2
            ),
            boardConfidence: 60 + raw.prestige * 3,
            manager: ClubManager(name: "Vacant", nationality: raw.country),
            players: players,
            seasonObjectives: generateObjectives(prestige: raw.prestige)
        )
    }

    private static func generateObjectives(prestige: Int) -> [String] {
        switch prestige {
        case 9...10: ["Win the League", "Reach Top 2"]
        case 7...8: ["Finish Top 4", "Reach Top 6"]
        case 5...6: ["Finish Top Half", "Avoid Relegation"]
        default: ["Avoid Relegation", "Develop Youth Players"]
        }
    }

    // MARK: - Fixture Generation

    private static func generateFixtures(teams: [String], competition: String) -> [Fixture] {
        var fixtures: [Fixture] = []
        var week = 1
        let teamCount = teams.count
        let rounds = (teamCount - 1) * 2

        for round in 0..<min(rounds, 38) {
            for i in stride(from: 0, to: teamCount - 1, by: 2) {
                let homeIdx = (i + round) % teamCount
                var awayIdx = (teamCount - 1 - i + round) % teamCount
                if awayIdx == homeIdx { awayIdx = (awayIdx + 1) % teamCount }
                if homeIdx < teamCount && awayIdx < teamCount && homeIdx != awayIdx {
                    fixtures.append(Fixture(
                        id: UUID().uuidString,
                        homeTeam: teams[homeIdx],
                        awayTeam: teams[awayIdx],
                        week: week,
                        competition: competition,
                        venue: "\(teams[homeIdx]) Stadium",
                        isPlayed: false
                    ))
                }
            }
            week += 1
        }
        return fixtures
    }

    // MARK: - JSON Loading

    private static func loadJSON<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        // Try app bundle root
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            return decode(type, from: url)
        }
        // Try "Database" subdirectory
        if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Database") {
            return decode(type, from: url)
        }
        // Try documents directory (for user-imported databases)
        let docsURL = URL.documentsDirectory.appending(path: "database/\(filename).json")
        if FileManager.default.fileExists(atPath: docsURL.path()) {
            return decode(type, from: docsURL)
        }
        return nil
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(type, from: data)
    }
}
