import SwiftUI

struct ClubOverviewView: View {
    let gameManager: GameManager
    @State private var showFinances: Bool = false
    @State private var showTraining: Bool = false
    @State private var showBoardRoom: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    clubHeader
                    menuGrid
                    staffSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(AppTheme.background)
            .navigationTitle("Club")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFinances) { FinancesView(gameManager: gameManager) }
            .sheet(isPresented: $showTraining) { TrainingView(gameManager: gameManager) }
            .sheet(isPresented: $showBoardRoom) { BoardRoomView(gameManager: gameManager) }
            .sheet(isPresented: $showSettings) { SettingsView(gameManager: gameManager) }
        }
        .preferredColorScheme(.dark)
    }

    private var clubHeader: some View {
        Group {
            if let club = gameManager.userClub {
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: club.primaryColor))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(club.shortName)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }

                    Text(club.name)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text(club.stadium.name)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("\(club.stadium.capacity.formatted()) seats")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Divider().frame(height: 30)

                        VStack(spacing: 2) {
                            Text("Manager")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(club.manager.name)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Divider().frame(height: 30)

                        VStack(spacing: 2) {
                            Text("Squad Value")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("€\(formatMoney(club.squadValue))")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.golden)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface, in: .rect(cornerRadius: 16))
            }
        }
    }

    private var menuGrid: some View {
        let items: [(String, String, Color, () -> Void)] = [
            ("Finances", "banknote.fill", AppTheme.pitchGreen, { showFinances = true }),
            ("Board Room", "building.2.fill", AppTheme.golden, { showBoardRoom = true }),
            ("Training", "figure.run", .orange, { showTraining = true }),
            ("Settings", "gearshape.fill", AppTheme.textSecondary, { showSettings = true }),
        ]

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(items, id: \.0) { item in
                Button { item.3() } label: {
                    VStack(spacing: 10) {
                        Image(systemName: item.1)
                            .font(.title2)
                            .foregroundStyle(item.2)
                        Text(item.0)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppTheme.surface, in: .rect(cornerRadius: 14))
                }
            }
        }
    }

    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Season Objectives")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(gameManager.userClub?.seasonObjectives ?? [], id: \.self) { objective in
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .foregroundStyle(AppTheme.golden)
                    Text(objective)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("In Progress")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(12)
                .background(AppTheme.surface, in: .rect(cornerRadius: 10))
            }
        }
    }

    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1_000_000 { return String(format: "%.1fM", Double(amount) / 1_000_000) }
        if amount >= 1_000 { return String(format: "%.0fK", Double(amount) / 1_000) }
        return "\(amount)"
    }
}

struct FinancesView: View {
    let gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let club = gameManager.userClub {
                        budgetCard(club: club)
                        wageBillSection(club: club)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("Finances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func budgetCard(club: Club) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transfer Budget")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("€\(formatMoney(club.budget.transfer))")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.pitchGreen)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wage Budget")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("€\(formatMoney(club.budget.wage))")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.golden)
                }
            }

            Divider().background(AppTheme.surfaceElevated)

            HStack {
                Text("Weekly Wage Bill")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("€\(club.totalWageBill.formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func wageBillSection(club: Club) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Highest Earners")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(club.players.sorted { $0.weeklyWage > $1.weeklyWage }.prefix(10)) { player in
                HStack {
                    Text(player.primaryPosition.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.positionColor(player.primaryPosition.category))
                        .frame(width: 28)
                    Text(player.shortName)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("€\(player.weeklyWage.formatted())/wk")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.golden)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1_000_000 { return String(format: "%.1fM", Double(amount) / 1_000_000) }
        if amount >= 1_000 { return String(format: "%.0fK", Double(amount) / 1_000) }
        return "\(amount)"
    }
}

struct TrainingView: View {
    @Bindable var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scheduleGrid
                    fitnessOverview
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var scheduleGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(0..<7, id: \.self) { day in
                HStack {
                    Text(days[day])
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 40, alignment: .leading)

                    Menu {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            Button {
                                gameManager.trainingSchedule[day] = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: gameManager.trainingSchedule[day].icon)
                                .frame(width: 20)
                            Text(gameManager.trainingSchedule[day].rawValue)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(10)
                        .background(AppTheme.surfaceElevated, in: .rect(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private var fitnessOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Squad Fitness")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(gameManager.userClub?.players.sorted { $0.currentFitness < $1.currentFitness }.prefix(10) ?? []) { player in
                HStack(spacing: 8) {
                    Text(player.shortName)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        let color: Color = player.currentFitness > 75 ? .green : player.currentFitness > 50 ? .yellow : .red
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppTheme.surfaceElevated).frame(height: 6)
                            Capsule().fill(color).frame(width: geo.size.width * Double(player.currentFitness) / 100.0, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(player.currentFitness)%")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }
}

struct BoardRoomView: View {
    let gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    confidenceGauge
                    objectivesList
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("Board Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var confidenceGauge: some View {
        let confidence = gameManager.userClub?.boardConfidence ?? 50
        let color: Color = confidence > 60 ? .green : confidence > 30 ? .orange : .red

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppTheme.surfaceElevated, lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: Double(confidence) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(confidence)%")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Confidence")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Text(confidence > 60 ? "The board is satisfied with your progress." : confidence > 30 ? "The board is growing concerned." : "Your position is under threat.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface, in: .rect(cornerRadius: 16))
    }

    private var objectivesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Season Objectives")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(gameManager.userClub?.seasonObjectives ?? [], id: \.self) { obj in
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .foregroundStyle(AppTheme.golden)
                    Text(obj)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.orange)
                }
                .padding(12)
                .background(AppTheme.surface, in: .rect(cornerRadius: 10))
            }
        }
    }
}

struct SettingsView: View {
    let gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Manager") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(gameManager.managerName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Season")
                        Spacer()
                        Text(gameManager.currentSeason)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Week")
                        Spacer()
                        Text("\(gameManager.currentWeek)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Game") {
                    Button("Save Game") {
                        gameManager.save()
                    }
                    Button("New Career", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Start New Career?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("New Career", role: .destructive) {
                    gameManager.phase = .onboarding
                    gameManager.currentWeek = 1
                    gameManager.news = []
                    gameManager.seasonResults = []
                    dismiss()
                }
            } message: {
                Text("This will delete your current save.")
            }
        }
        .preferredColorScheme(.dark)
    }
}
