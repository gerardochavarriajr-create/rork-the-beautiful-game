import SwiftUI

struct SquadListView: View {
    let gameManager: GameManager
    @State private var selectedSegment: Int = 0
    @State private var sortOption: SortOption = .position
    @State private var positionFilters: Set<PositionCategory> = []
    @State private var selectedPlayer: Player?
    @State private var showFormation: Bool = false

    private var filteredPlayers: [Player] {
        guard let club = gameManager.userClub else { return [] }
        var players = club.players

        if selectedSegment == 1 {
            players = players.filter { $0.age < 21 }
        }

        if !positionFilters.isEmpty {
            players = players.filter { positionFilters.contains($0.primaryPosition.category) }
        }

        switch sortOption {
        case .position:
            let order: [PositionCategory] = [.goalkeeper, .defender, .midfielder, .attacker]
            players.sort { order.firstIndex(of: $0.primaryPosition.category)! < order.firstIndex(of: $1.primaryPosition.category)! }
        case .rating:
            players.sort { $0.overallRating > $1.overallRating }
        case .age:
            players.sort { $0.age < $1.age }
        case .name:
            players.sort { $0.lastName < $1.lastName }
        case .wage:
            players.sort { $0.weeklyWage > $1.weeklyWage }
        }
        return players
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                playerList
            }
            .background(AppTheme.background)
            .navigationTitle("Squad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFormation = true } label: {
                        Image(systemName: "sportscourt.fill")
                            .foregroundStyle(AppTheme.pitchGreen)
                    }
                }
            }
            .sheet(item: $selectedPlayer) { player in
                PlayerDetailView(player: player, gameManager: gameManager)
            }
            .sheet(isPresented: $showFormation) {
                FormationPickerView(gameManager: gameManager)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filterBar: some View {
        VStack(spacing: 10) {
            Picker("Segment", selection: $selectedSegment) {
                Text("First Team").tag(0)
                Text("Youth").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(PositionCategory.allCases, id: \.self) { cat in
                            Button {
                                if positionFilters.contains(cat) {
                                    positionFilters.remove(cat)
                                } else {
                                    positionFilters.insert(cat)
                                }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(positionFilters.contains(cat) ? AppTheme.positionColor(cat) : AppTheme.surfaceElevated, in: Capsule())
                                    .foregroundStyle(positionFilters.contains(cat) ? .white : AppTheme.textSecondary)
                            }
                        }

                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortOption.rawValue)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.surfaceElevated, in: Capsule())
                            .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
        .padding(.vertical, 10)
        .background(AppTheme.background)
    }

    private var playerList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredPlayers) { player in
                    Button { selectedPlayer = player } label: {
                        PlayerRow(player: player)
                    }
                }
            }
        }
    }
}

struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text(player.primaryPosition.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppTheme.positionColor(player.primaryPosition.category), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.fullName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    if player.isInjured {
                        Image(systemName: "cross.case.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    if player.isSuspended {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    if player.isOnLoan {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                HStack(spacing: 8) {
                    Text(player.nationalityFlag)
                        .font(.caption)
                    Text("Age \(player.age)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    fitnessBar(value: player.currentFitness)
                }
            }

            Spacer()

            Text("\(player.overallRating)")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ratingColor(player.overallRating))
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
    }

    private func fitnessBar(value: Int) -> some View {
        let color: Color = value > 75 ? .green : value > 50 ? .yellow : .red
        return GeometryReader { _ in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.surfaceElevated)
                    .frame(height: 4)
                Capsule()
                    .fill(color)
                    .frame(width: CGFloat(value) / 100.0 * 40, height: 4)
            }
        }
        .frame(width: 40, height: 4)
    }
}

private enum SortOption: String, CaseIterable {
    case position = "Position"
    case rating = "Rating"
    case age = "Age"
    case name = "Name"
    case wage = "Wage"
}
