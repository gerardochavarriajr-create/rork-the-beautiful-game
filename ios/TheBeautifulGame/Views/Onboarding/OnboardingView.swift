import SwiftUI

struct OnboardingView: View {
    let gameManager: GameManager
    @State private var step: OnboardingStep = .welcome
    @State private var selectedLeague: LeagueInfo?
    @State private var selectedClub: Club?
    @State private var managerName: String = ""
    @State private var appeared: Bool = false

    private let leagues = DatabaseGenerator.generateLeagues()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch step {
            case .welcome:
                welcomeView
            case .pickLeague:
                leaguePickerView
            case .pickTeam:
                if let league = selectedLeague {
                    teamPickerView(league: league)
                }
            case .confirm:
                if let club = selectedClub {
                    confirmView(club: club)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppTheme.golden)
                    .symbolEffect(.pulse, options: .repeating)

                Text("The Beautiful Game")
                    .font(.system(.largeTitle, design: .default, weight: .black))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Your club. Your story.")
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4)) { step = .pickLeague }
            } label: {
                Text("New Career")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.golden, in: .rect(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
        }
    }

    private var leaguePickerView: some View {
        VStack(spacing: 0) {
            headerBar(title: "Pick Your League", showBack: true) {
                withAnimation(.spring(response: 0.3)) { step = .welcome }
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(leagues) { league in
                        Button {
                            selectedLeague = league
                            withAnimation(.spring(response: 0.3)) { step = .pickTeam }
                        } label: {
                            HStack(spacing: 16) {
                                Text(league.flagEmoji)
                                    .font(.title)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(league.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(league.teamCount) teams")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(16)
                            .background(AppTheme.surface, in: .rect(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }

    private func teamPickerView(league: LeagueInfo) -> some View {
        let leagueData = DatabaseGenerator.generateLeagueData(for: league)

        return VStack(spacing: 0) {
            headerBar(title: league.name, showBack: true) {
                withAnimation(.spring(response: 0.3)) { step = .pickLeague }
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(leagueData.clubs) { club in
                        Button {
                            selectedClub = club
                            withAnimation(.spring(response: 0.3)) { step = .confirm }
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(hex: club.primaryColor))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Text(String(club.shortName.prefix(2)))
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(club.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(club.city)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                HStack(spacing: 2) {
                                    ForEach(0..<5, id: \.self) { i in
                                        Image(systemName: i < (club.prestige / 2) ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.golden)
                                    }
                                }

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .font(.caption)
                            }
                            .padding(14)
                            .background(AppTheme.surface, in: .rect(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    private func confirmView(club: Club) -> some View {
        VStack(spacing: 0) {
            headerBar(title: "Confirm", showBack: true) {
                withAnimation(.spring(response: 0.3)) { step = .pickTeam }
            }

            ScrollView {
                VStack(spacing: 24) {
                    Circle()
                        .fill(Color(hex: club.primaryColor))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Text(club.shortName)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 24)

                    Text(club.name)
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    VStack(spacing: 12) {
                        infoRow(label: "Stadium", value: club.stadium.name)
                        infoRow(label: "Capacity", value: "\(club.stadium.capacity.formatted())")
                        infoRow(label: "Budget", value: "€\(formatMoney(club.budget.total))")
                        infoRow(label: "Squad Size", value: "\(club.players.count) players")
                    }
                    .padding(16)
                    .background(AppTheme.surface, in: .rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manager Name")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        TextField("Enter your name", text: $managerName)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(AppTheme.surfaceElevated, in: .rect(cornerRadius: 10))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Button {
                        let name = managerName.isEmpty ? "Manager" : managerName
                        gameManager.startCareer(leagueID: selectedLeague!.id, clubID: club.id, manager: name)
                    } label: {
                        Text("Start Career")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.golden, in: .rect(cornerRadius: 14))
                    }
                    .sensoryFeedback(.impact(weight: .heavy), trigger: gameManager.phase)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func headerBar(title: String, showBack: Bool, backAction: @escaping () -> Void) -> some View {
        HStack {
            if showBack {
                Button { backAction() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if showBack {
                Color.clear.frame(width: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", Double(amount) / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", Double(amount) / 1_000)
        }
        return "\(amount)"
    }
}

private enum OnboardingStep {
    case welcome, pickLeague, pickTeam, confirm
}
