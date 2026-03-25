import SwiftUI

struct TransferHubView: View {
    let gameManager: GameManager
    @State private var selectedSegment: Int = 0
    @State private var searchText: String = ""
    @State private var positionFilter: PositionCategory?
    @State private var minRating: Double = 40
    @State private var maxAge: Double = 40
    @State private var selectedPlayer: Player?
    @State private var showOfferSheet: Bool = false
    @State private var offerPlayer: Player?
    @State private var offerAmount: String = ""

    private var searchResults: [Player] {
        guard let league = gameManager.league else { return [] }
        var allPlayers: [Player] = []
        for club in league.clubs where club.id != gameManager.userClubID {
            for player in club.players {
                allPlayers.append(player)
            }
        }

        if !searchText.isEmpty {
            allPlayers = allPlayers.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
        }
        if let filter = positionFilter {
            allPlayers = allPlayers.filter { $0.primaryPosition.category == filter }
        }
        allPlayers = allPlayers.filter { $0.overallRating >= Int(minRating) && $0.age <= Int(maxAge) }
        return allPlayers.sorted { $0.overallRating > $1.overallRating }.prefix(50).map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSegment) {
                    Text("Search").tag(0)
                    Text("Shortlist").tag(1)
                    Text("Deals").tag(2)
                    Text("History").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch selectedSegment {
                case 0: searchView
                case 1: shortlistView
                case 2: negotiationsView
                default: historyView
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Transfers")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedPlayer) { player in
                PlayerDetailView(player: player, gameManager: gameManager)
            }
            .sheet(isPresented: $showOfferSheet) {
                offerSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Search players...", text: $searchText)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(10)
                .background(AppTheme.surfaceElevated, in: .rect(cornerRadius: 10))
                .padding(.horizontal, 16)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(PositionCategory.allCases, id: \.self) { cat in
                            Button {
                                positionFilter = positionFilter == cat ? nil : cat
                            } label: {
                                Text(cat.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(positionFilter == cat ? AppTheme.positionColor(cat) : AppTheme.surfaceElevated, in: Capsule())
                                    .foregroundStyle(positionFilter == cat ? .white : AppTheme.textSecondary)
                            }
                        }

                        Text("Min \(Int(minRating))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Slider(value: $minRating, in: 30...90, step: 5)
                            .frame(width: 80)
                            .tint(AppTheme.pitchGreen)

                        Text("Max \(Int(maxAge))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Slider(value: $maxAge, in: 16...40, step: 1)
                            .frame(width: 80)
                            .tint(AppTheme.pitchGreen)
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(searchResults) { player in
                        transferPlayerRow(player: player)
                    }
                }
            }
        }
    }

    private func transferPlayerRow(player: Player) -> some View {
        HStack(spacing: 12) {
            Text(player.primaryPosition.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AppTheme.positionColor(player.primaryPosition.category), in: .rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(player.nationalityFlag)
                        .font(.caption)
                    Text("Age \(player.age)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("€\(formatMoney(player.marketValue))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.golden)
                }
            }

            Spacer()

            Text("\(player.overallRating)")
                .font(.headline.bold())
                .foregroundStyle(AppTheme.ratingColor(player.overallRating))

            Menu {
                Button { selectedPlayer = player } label: { Label("View Profile", systemImage: "person.circle") }
                Button {
                    if !gameManager.shortlist.contains(player.id) {
                        gameManager.shortlist.append(player.id)
                    }
                } label: { Label("Add to Shortlist", systemImage: "star") }
                Button {
                    offerPlayer = player
                    offerAmount = "\(player.marketValue)"
                    showOfferSheet = true
                } label: { Label("Make Offer", systemImage: "banknote") }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.surface)
    }

    private var shortlistView: some View {
        Group {
            let shortlistedPlayers = findShortlistedPlayers()
            if shortlistedPlayers.isEmpty {
                ContentUnavailableView("No Shortlisted Players", systemImage: "star", description: Text("Search for players and add them to your shortlist."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(shortlistedPlayers) { player in
                            transferPlayerRow(player: player)
                        }
                    }
                }
            }
        }
    }

    private var negotiationsView: some View {
        Group {
            let active = gameManager.negotiations.filter { $0.status == .pending || $0.status == .counterOffer }
            if active.isEmpty {
                ContentUnavailableView("No Active Negotiations", systemImage: "arrow.left.arrow.right", description: Text("Make an offer on a player to start negotiating."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(active) { offer in
                            negotiationCard(offer: offer)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
    }

    private func negotiationCard(offer: TransferOffer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(offer.playerName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(offer.status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor(offer.status).opacity(0.2), in: Capsule())
                    .foregroundStyle(statusColor(offer.status))
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Offer")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("€\(formatMoney(offer.offerAmount))")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.pitchGreen)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Asking Price")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("€\(formatMoney(offer.askingPrice))")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.golden)
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: .rect(cornerRadius: 12))
    }

    private var historyView: some View {
        Group {
            let completed = gameManager.transferHistory
            if completed.isEmpty {
                ContentUnavailableView("No Transfer History", systemImage: "clock", description: Text("Completed transfers will appear here."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(completed) { offer in
                            negotiationCard(offer: offer)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
    }

    private var offerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let player = offerPlayer {
                    VStack(spacing: 8) {
                        Text(player.fullName)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(player.primaryPosition.displayName) • \(player.overallRating) OVR")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Market Value: €\(formatMoney(player.marketValue))")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.golden)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transfer Fee")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Amount", text: $offerAmount)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(AppTheme.surfaceElevated, in: .rect(cornerRadius: 10))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Text("Budget: €\(formatMoney(gameManager.userClub?.budget.transfer ?? 0))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background)
            .navigationTitle("Make Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showOfferSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitOffer()
                        showOfferSheet = false
                    }
                    .foregroundStyle(AppTheme.pitchGreen)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func submitOffer() {
        guard let player = offerPlayer, let amount = Int(offerAmount) else { return }
        let offer = TransferOffer(
            id: UUID().uuidString,
            playerID: player.id,
            playerName: player.fullName,
            fromClub: findPlayerClub(player)?.name ?? "Unknown",
            toClub: gameManager.userClub?.name ?? "Unknown",
            offerAmount: amount,
            askingPrice: Int(Double(player.marketValue) * 1.2),
            weeklyWage: player.weeklyWage,
            contractYears: 3,
            status: .pending,
            week: gameManager.currentWeek
        )
        gameManager.negotiations.append(offer)
    }

    private func findPlayerClub(_ player: Player) -> Club? {
        gameManager.league?.clubs.first { $0.players.contains(where: { $0.id == player.id }) }
    }

    private func findShortlistedPlayers() -> [Player] {
        guard let league = gameManager.league else { return [] }
        var result: [Player] = []
        for club in league.clubs {
            for player in club.players where gameManager.shortlist.contains(player.id) {
                result.append(player)
            }
        }
        return result
    }

    private func statusColor(_ status: TransferStatus) -> Color {
        switch status {
        case .pending: .orange
        case .accepted: .green
        case .rejected: .red
        case .counterOffer: .blue
        case .completed: AppTheme.pitchGreen
        }
    }

    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1_000_000 { return String(format: "%.1fM", Double(amount) / 1_000_000) }
        if amount >= 1_000 { return String(format: "%.0fK", Double(amount) / 1_000) }
        return "\(amount)"
    }
}
