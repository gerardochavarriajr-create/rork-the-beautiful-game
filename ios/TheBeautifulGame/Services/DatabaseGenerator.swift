import Foundation

struct DatabaseGenerator {
    static func generateLeagues() -> [LeagueInfo] {
        [
            LeagueInfo(id: "premier_league", name: "Premier League", country: "England", flagEmoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", teamCount: 20),
            LeagueInfo(id: "la_liga", name: "La Liga", country: "Spain", flagEmoji: "🇪🇸", teamCount: 20),
            LeagueInfo(id: "serie_a", name: "Serie A", country: "Italy", flagEmoji: "🇮🇹", teamCount: 20),
            LeagueInfo(id: "bundesliga", name: "Bundesliga", country: "Germany", flagEmoji: "🇩🇪", teamCount: 18),
            LeagueInfo(id: "ligue_1", name: "Ligue 1", country: "France", flagEmoji: "🇫🇷", teamCount: 18),
        ]
    }

    static func generateLeagueData(for leagueInfo: LeagueInfo) -> LeagueData {
        let teamDefs = teamDefinitions(for: leagueInfo.id)
        var clubs: [Club] = []
        for def in teamDefs {
            let club = generateClub(def: def, league: leagueInfo.name)
            clubs.append(club)
        }
        let table = clubs.map { club in
            LeagueTableRow(teamName: club.name, isUserTeam: false)
        }
        let fixtures = generateFixtures(teams: clubs.map(\.name), competition: leagueInfo.name)
        return LeagueData(info: leagueInfo, table: table, fixtures: fixtures, clubs: clubs)
    }

    private static func generateClub(def: TeamDef, league: String) -> Club {
        var players: [Player] = []
        let squadTemplate: [(PlayerPosition, Int)] = [
            (.GK, 2), (.CB, 4), (.RB, 2), (.LB, 2),
            (.CM, 3), (.DM, 1), (.RM, 1), (.LM, 1),
            (.RW, 1), (.LW, 1), (.AM, 1), (.ST, 2), (.CF, 1)
        ]
        for (pos, count) in squadTemplate {
            for _ in 0..<count {
                let player = generatePlayer(position: pos, clubPrestige: def.prestige, nationality: def.country)
                players.append(player)
            }
        }
        let budgetBase = def.prestige * def.prestige * 500_000
        return Club(
            id: def.id,
            name: def.name,
            shortName: def.shortName,
            city: def.city,
            stadium: Stadium(name: def.stadium, capacity: def.stadiumCapacity),
            league: league,
            prestige: def.prestige,
            primaryColor: def.primaryColor,
            secondaryColor: def.secondaryColor,
            budget: ClubBudget(transfer: budgetBase, wage: budgetBase / 2, total: budgetBase + budgetBase / 2),
            boardConfidence: 65 + Int.random(in: 0...20),
            manager: ClubManager(name: "Vacant", nationality: def.country),
            players: players,
            seasonObjectives: generateObjectives(prestige: def.prestige)
        )
    }

    static func generatePlayer(position: PlayerPosition, clubPrestige: Int, nationality: String) -> Player {
        let firstNames = ["James", "Oliver", "Lucas", "Marco", "Pedro", "Carlos", "Bruno", "Luka", "Marcus", "Kai", "Jamal", "Phil", "Leon", "Erling", "Mohamed", "Kevin", "Son", "Bukayo", "Declan", "William", "Raphael", "Victor", "Alejandro", "Diego", "Mateo", "Hugo", "Arthur", "Thomas", "Antoine", "Kylian", "Ousmane", "Jules", "Theo", "Rafael", "Nico", "Florian", "Joshua", "Leroy", "Timo", "Serge"]
        let lastNames = ["Smith", "Johnson", "Silva", "Santos", "Mueller", "Hernandez", "Garcia", "Martinez", "Rodriguez", "Fernandez", "Williams", "Brown", "Jones", "Wilson", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Robinson", "Clark", "Lewis", "Walker", "Young", "King", "Wright", "Lopez", "Hill", "Scott", "Green", "Adams", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter"]
        let styles: [PlayerPosition: [String]] = [
            .ST: ["Target Man", "Poacher", "Complete Forward"],
            .CF: ["False Nine", "Deep-Lying Forward", "Trequartista"],
            .AM: ["Playmaker", "Shadow Striker", "Enganche"],
            .CM: ["Box to Box", "Deep-Lying Playmaker", "Mezzala"],
            .DM: ["Anchor Man", "Ball Winner", "Regista"],
            .CB: ["Ball-Playing CB", "Stopper", "Libero"],
            .RW: ["Inside Forward", "Inverted Winger", "Traditional Winger"],
            .LW: ["Inside Forward", "Inverted Winger", "Traditional Winger"],
        ]
        let countries = ["England", "Spain", "France", "Germany", "Italy", "Brazil", "Argentina", "Portugal", "Netherlands", "Belgium"]
        let flags = ["England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Spain": "🇪🇸", "France": "🇫🇷", "Germany": "🇩🇪", "Italy": "🇮🇹", "Brazil": "🇧🇷", "Argentina": "🇦🇷", "Portugal": "🇵🇹", "Netherlands": "🇳🇱", "Belgium": "🇧🇪"]

        let age = Int.random(in: 18...34)
        let baseRating = max(40, min(92, clubPrestige * 8 + Int.random(in: -15...15)))
        let firstName = firstNames.randomElement()!
        let lastName = lastNames.randomElement()!
        let playerCountry = Bool.random() ? nationality : countries.randomElement()!
        let flag = flags[playerCountry] ?? "🏳️"

        let attrs = generateAttributes(baseRating: baseRating, position: position, age: age)
        let overall = Player.computeOverall(for: attrs, position: position)
        let wage = max(5_000, overall * overall * 10 + Int.random(in: -5000...5000))
        let value = wage * 52 * Int.random(in: 2...5)

        let squadStatus: SquadStatus
        switch overall {
        case 80...99: squadStatus = .keyPlayer
        case 72...79: squadStatus = .firstTeam
        case 65...71: squadStatus = .rotation
        case 55...64: squadStatus = .backup
        default: squadStatus = age < 21 ? .youngster : .backup
        }

        return Player(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            age: age,
            nationality: playerCountry,
            nationalityFlag: flag,
            primaryPosition: position,
            secondaryPositions: [],
            style: styles[position]?.randomElement(),
            attributes: attrs,
            overallRating: overall,
            morale: Int.random(in: 55...90),
            currentFitness: Int.random(in: 70...100),
            form: Int.random(in: 5...15),
            contractExpiry: 2026 + Int.random(in: 1...4),
            weeklyWage: wage,
            squadStatus: squadStatus,
            isInjured: false,
            injuryDescription: nil,
            injuryWeeksRemaining: nil,
            isSuspended: false,
            suspensionWeeksRemaining: nil,
            seasonStats: SeasonStats(),
            marketValue: value,
            isOnLoan: false
        )
    }

    private static func generateAttributes(baseRating: Int, position: PlayerPosition, age: Int) -> PlayerAttributes {
        func attr(_ bias: Int = 0) -> Int {
            let ageFactor = age < 22 ? -3 : (age > 30 ? -2 : 0)
            return max(1, min(99, baseRating + bias + Int.random(in: -12...12) + ageFactor))
        }

        let isGK = position == .GK
        let isDef = position.category == .defender
        let isMid = position.category == .midfielder
        let isAtt = position.category == .attacker

        return PlayerAttributes(
            ballControl: attr(isMid ? 5 : isAtt ? 5 : -5),
            crossing: attr(position == .RM || position == .LM || position == .RW || position == .LW ? 8 : -3),
            dribbling: attr(isAtt ? 5 : isMid ? 3 : -8),
            finishing: attr(isAtt ? 10 : isMid ? -2 : -15),
            heading: attr(position == .ST || position == .CB ? 5 : -3),
            longShots: attr(isMid ? 3 : isAtt ? 2 : -5),
            marking: attr(isDef ? 8 : -8),
            passing: attr(isMid ? 8 : -2),
            setPieces: attr(-5),
            shotPower: attr(isAtt ? 3 : -3),
            tackling: attr(isDef ? 10 : position == .DM ? 8 : -10),
            technique: attr(isAtt ? 5 : isMid ? 5 : -5),
            throwing: attr(isGK ? 10 : -20),
            acceleration: attr(isAtt ? 3 : 0),
            agility: attr(isAtt ? 3 : isMid ? 2 : -2),
            balance: attr(0),
            jumping: attr(position == .CB || position == .GK ? 5 : -2),
            pace: attr(isAtt ? 5 : isDef ? -2 : 0),
            stamina: attr(isMid ? 5 : 0),
            strength: attr(isDef ? 3 : position == .ST ? 3 : -2),
            fitness: attr(0),
            naturalFitness: attr(0),
            aggression: attr(isDef ? 3 : -2),
            anticipation: attr(2),
            composure: attr(isAtt ? 3 : 0),
            concentration: attr(isDef ? 5 : isGK ? 5 : 0),
            creativity: attr(isMid ? 5 : isAtt ? 3 : -8),
            decisions: attr(2),
            determination: attr(0),
            flair: attr(isAtt ? 5 : isMid ? 3 : -8),
            leadership: attr(-5),
            positioning: attr(isDef ? 5 : isGK ? 5 : isAtt ? 3 : 0),
            workRate: attr(isMid ? 3 : 0),
            aerialAbility: attr(isGK ? 10 : -20),
            commandOfArea: attr(isGK ? 10 : -25),
            communication: attr(isGK ? 8 : -20),
            handling: attr(isGK ? 12 : -25),
            kicking: attr(isGK ? 8 : -20),
            oneOnOnes: attr(isGK ? 10 : -25),
            reflexes: attr(isGK ? 12 : -20),
            rushingOut: attr(isGK ? 8 : -25)
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
                    let fixture = Fixture(
                        id: UUID().uuidString,
                        homeTeam: teams[homeIdx],
                        awayTeam: teams[awayIdx],
                        week: week,
                        competition: competition,
                        venue: "\(teams[homeIdx]) Stadium",
                        isPlayed: false
                    )
                    fixtures.append(fixture)
                }
            }
            week += 1
        }
        return fixtures
    }

    struct TeamDef {
        let id: String
        let name: String
        let shortName: String
        let city: String
        let stadium: String
        let stadiumCapacity: Int
        let prestige: Int
        let primaryColor: String
        let secondaryColor: String
        let country: String
    }

    private static func teamDefinitions(for leagueID: String) -> [TeamDef] {
        switch leagueID {
        case "premier_league":
            return [
                TeamDef(id: "mci", name: "Manchester City", shortName: "MCI", city: "Manchester", stadium: "Etihad Stadium", stadiumCapacity: 53400, prestige: 10, primaryColor: "#6CABDD", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "ars", name: "Arsenal", shortName: "ARS", city: "London", stadium: "Emirates Stadium", stadiumCapacity: 60704, prestige: 9, primaryColor: "#EF0107", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "liv", name: "Liverpool", shortName: "LIV", city: "Liverpool", stadium: "Anfield", stadiumCapacity: 61276, prestige: 9, primaryColor: "#C8102E", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "mun", name: "Manchester United", shortName: "MUN", city: "Manchester", stadium: "Old Trafford", stadiumCapacity: 74310, prestige: 8, primaryColor: "#DA291C", secondaryColor: "#FBE122", country: "England"),
                TeamDef(id: "che", name: "Chelsea", shortName: "CHE", city: "London", stadium: "Stamford Bridge", stadiumCapacity: 40834, prestige: 8, primaryColor: "#034694", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "tot", name: "Tottenham", shortName: "TOT", city: "London", stadium: "Tottenham Stadium", stadiumCapacity: 62850, prestige: 7, primaryColor: "#132257", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "new", name: "Newcastle United", shortName: "NEW", city: "Newcastle", stadium: "St James' Park", stadiumCapacity: 52305, prestige: 7, primaryColor: "#241F20", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "avl", name: "Aston Villa", shortName: "AVL", city: "Birmingham", stadium: "Villa Park", stadiumCapacity: 42657, prestige: 7, primaryColor: "#670E36", secondaryColor: "#95BFE5", country: "England"),
                TeamDef(id: "whu", name: "West Ham", shortName: "WHU", city: "London", stadium: "London Stadium", stadiumCapacity: 62500, prestige: 6, primaryColor: "#7A263A", secondaryColor: "#1BB1E7", country: "England"),
                TeamDef(id: "bha", name: "Brighton", shortName: "BHA", city: "Brighton", stadium: "Amex Stadium", stadiumCapacity: 31800, prestige: 6, primaryColor: "#0057B8", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "cry", name: "Crystal Palace", shortName: "CRY", city: "London", stadium: "Selhurst Park", stadiumCapacity: 25486, prestige: 5, primaryColor: "#1B458F", secondaryColor: "#C4122E", country: "England"),
                TeamDef(id: "ful", name: "Fulham", shortName: "FUL", city: "London", stadium: "Craven Cottage", stadiumCapacity: 25700, prestige: 5, primaryColor: "#FFFFFF", secondaryColor: "#000000", country: "England"),
                TeamDef(id: "wol", name: "Wolves", shortName: "WOL", city: "Wolverhampton", stadium: "Molineux", stadiumCapacity: 32050, prestige: 5, primaryColor: "#FDB913", secondaryColor: "#231F20", country: "England"),
                TeamDef(id: "bou", name: "Bournemouth", shortName: "BOU", city: "Bournemouth", stadium: "Vitality Stadium", stadiumCapacity: 11364, prestige: 5, primaryColor: "#DA291C", secondaryColor: "#000000", country: "England"),
                TeamDef(id: "nfo", name: "Nottingham Forest", shortName: "NFO", city: "Nottingham", stadium: "City Ground", stadiumCapacity: 30445, prestige: 5, primaryColor: "#DD0000", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "bre", name: "Brentford", shortName: "BRE", city: "London", stadium: "Gtech Stadium", stadiumCapacity: 17250, prestige: 5, primaryColor: "#E30613", secondaryColor: "#FFB81C", country: "England"),
                TeamDef(id: "eve", name: "Everton", shortName: "EVE", city: "Liverpool", stadium: "Goodison Park", stadiumCapacity: 39414, prestige: 5, primaryColor: "#003399", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "lei", name: "Leicester City", shortName: "LEI", city: "Leicester", stadium: "King Power Stadium", stadiumCapacity: 32261, prestige: 5, primaryColor: "#003090", secondaryColor: "#FDBE11", country: "England"),
                TeamDef(id: "ips", name: "Ipswich Town", shortName: "IPS", city: "Ipswich", stadium: "Portman Road", stadiumCapacity: 30311, prestige: 4, primaryColor: "#0044AA", secondaryColor: "#FFFFFF", country: "England"),
                TeamDef(id: "sou", name: "Southampton", shortName: "SOU", city: "Southampton", stadium: "St Mary's Stadium", stadiumCapacity: 32384, prestige: 4, primaryColor: "#D71920", secondaryColor: "#FFFFFF", country: "England"),
            ]
        case "la_liga":
            return [
                TeamDef(id: "rma", name: "Real Madrid", shortName: "RMA", city: "Madrid", stadium: "Santiago Bernabéu", stadiumCapacity: 81044, prestige: 10, primaryColor: "#FFFFFF", secondaryColor: "#FEBE10", country: "Spain"),
                TeamDef(id: "fcb", name: "Barcelona", shortName: "FCB", city: "Barcelona", stadium: "Spotify Camp Nou", stadiumCapacity: 99354, prestige: 10, primaryColor: "#A50044", secondaryColor: "#004D98", country: "Spain"),
                TeamDef(id: "atm", name: "Atletico Madrid", shortName: "ATM", city: "Madrid", stadium: "Metropolitano", stadiumCapacity: 68456, prestige: 8, primaryColor: "#CE3524", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "rsoc", name: "Real Sociedad", shortName: "RSO", city: "San Sebastián", stadium: "Anoeta", stadiumCapacity: 39500, prestige: 7, primaryColor: "#003DA5", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "bet", name: "Real Betis", shortName: "BET", city: "Seville", stadium: "Benito Villamarín", stadiumCapacity: 60720, prestige: 6, primaryColor: "#00954C", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "vil", name: "Villarreal", shortName: "VIL", city: "Villarreal", stadium: "Estadio de la Cerámica", stadiumCapacity: 23500, prestige: 7, primaryColor: "#FFE114", secondaryColor: "#005DAA", country: "Spain"),
                TeamDef(id: "sev", name: "Sevilla", shortName: "SEV", city: "Seville", stadium: "Ramón Sánchez-Pizjuán", stadiumCapacity: 43883, prestige: 7, primaryColor: "#FFFFFF", secondaryColor: "#D4021D", country: "Spain"),
                TeamDef(id: "ath", name: "Athletic Bilbao", shortName: "ATH", city: "Bilbao", stadium: "San Mamés", stadiumCapacity: 53289, prestige: 7, primaryColor: "#EE2523", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "val", name: "Valencia", shortName: "VAL", city: "Valencia", stadium: "Mestalla", stadiumCapacity: 49430, prestige: 6, primaryColor: "#FFFFFF", secondaryColor: "#EE3524", country: "Spain"),
                TeamDef(id: "osa", name: "Osasuna", shortName: "OSA", city: "Pamplona", stadium: "El Sadar", stadiumCapacity: 23576, prestige: 5, primaryColor: "#D91A2A", secondaryColor: "#14213D", country: "Spain"),
                TeamDef(id: "get", name: "Getafe", shortName: "GET", city: "Getafe", stadium: "Coliseum", stadiumCapacity: 17393, prestige: 5, primaryColor: "#005999", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "cel", name: "Celta Vigo", shortName: "CEL", city: "Vigo", stadium: "Balaídos", stadiumCapacity: 29000, prestige: 5, primaryColor: "#8AC3EE", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "rcd", name: "Espanyol", shortName: "ESP", city: "Barcelona", stadium: "RCDE Stadium", stadiumCapacity: 40000, prestige: 5, primaryColor: "#007FC8", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "ray", name: "Rayo Vallecano", shortName: "RAY", city: "Madrid", stadium: "Vallecas", stadiumCapacity: 14708, prestige: 4, primaryColor: "#FFFFFF", secondaryColor: "#E53027", country: "Spain"),
                TeamDef(id: "mlr", name: "Mallorca", shortName: "MLL", city: "Palma", stadium: "Son Moix", stadiumCapacity: 23142, prestige: 5, primaryColor: "#CE1126", secondaryColor: "#000000", country: "Spain"),
                TeamDef(id: "gir", name: "Girona", shortName: "GIR", city: "Girona", stadium: "Montilivi", stadiumCapacity: 14286, prestige: 5, primaryColor: "#CD2534", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "ala", name: "Alavés", shortName: "ALA", city: "Vitoria-Gasteiz", stadium: "Mendizorroza", stadiumCapacity: 19840, prestige: 4, primaryColor: "#003DA5", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "lpa", name: "Las Palmas", shortName: "LPA", city: "Las Palmas", stadium: "Gran Canaria", stadiumCapacity: 32400, prestige: 4, primaryColor: "#FFE114", secondaryColor: "#003DA5", country: "Spain"),
                TeamDef(id: "leg", name: "Leganés", shortName: "LEG", city: "Leganés", stadium: "Butarque", stadiumCapacity: 12450, prestige: 4, primaryColor: "#003DA5", secondaryColor: "#FFFFFF", country: "Spain"),
                TeamDef(id: "vll", name: "Valladolid", shortName: "VLL", city: "Valladolid", stadium: "José Zorrilla", stadiumCapacity: 26512, prestige: 4, primaryColor: "#55207B", secondaryColor: "#FFFFFF", country: "Spain"),
            ]
        default:
            return generateGenericTeams(count: leagueInfo(for: leagueID)?.teamCount ?? 18, country: leagueCountry(for: leagueID))
        }
    }

    private static func leagueInfo(for id: String) -> LeagueInfo? {
        generateLeagues().first { $0.id == id }
    }

    private static func leagueCountry(for id: String) -> String {
        switch id {
        case "serie_a": "Italy"
        case "bundesliga": "Germany"
        case "ligue_1": "France"
        default: "England"
        }
    }

    private static func generateGenericTeams(count: Int, country: String) -> [TeamDef] {
        let cityNames: [String: [String]] = [
            "Italy": ["Milan", "Rome", "Turin", "Naples", "Florence", "Genoa", "Bologna", "Venice", "Verona", "Bergamo", "Udine", "Cagliari", "Parma", "Lecce", "Monza", "Empoli", "Sassuolo", "Salerno", "Frosinone", "Como"],
            "Germany": ["Munich", "Dortmund", "Leipzig", "Berlin", "Leverkusen", "Frankfurt", "Stuttgart", "Wolfsburg", "Freiburg", "Hoffenheim", "Bremen", "Augsburg", "Mainz", "Cologne", "Bochum", "Heidenheim", "Darmstadt", "Hamburg"],
            "France": ["Paris", "Marseille", "Lyon", "Monaco", "Lille", "Nice", "Rennes", "Lens", "Strasbourg", "Toulouse", "Montpellier", "Nantes", "Reims", "Brest", "Le Havre", "Metz", "Lorient", "Clermont"],
        ]
        let cities = cityNames[country] ?? cityNames["Italy"]!
        let prestigeLevels = [10, 8, 8, 7, 7, 6, 6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4]
        return (0..<count).map { i in
            let city = i < cities.count ? cities[i] : "City\(i)"
            let prestige = i < prestigeLevels.count ? prestigeLevels[i] : 4
            return TeamDef(
                id: "\(country.lowercased())_\(i)",
                name: "FC \(city)",
                shortName: String(city.prefix(3)).uppercased(),
                city: city,
                stadium: "\(city) Arena",
                stadiumCapacity: Int.random(in: 15000...80000),
                prestige: prestige,
                primaryColor: "#\(String(format: "%06X", Int.random(in: 0...0xFFFFFF)))",
                secondaryColor: "#FFFFFF",
                country: country
            )
        }
    }
}
