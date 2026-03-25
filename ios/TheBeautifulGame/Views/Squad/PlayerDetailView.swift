import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    let gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAttrTab: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    radarChart
                    attributesSection
                    statsSection
                    contractSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(AppTheme.background)
            .navigationTitle(player.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.positionColor(player.primaryPosition.category))
                        .frame(width: 70, height: 70)
                    Text("\(player.overallRating)")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.fullName)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 8) {
                        Text(player.primaryPosition.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.positionColor(player.primaryPosition.category), in: Capsule())
                            .foregroundStyle(.white)

                        if let style = player.style {
                            Text(style)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(player.nationalityFlag)
                        Text(player.nationality)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("•")
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Age \(player.age)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 16) {
                statusBadge(label: player.squadStatus.rawValue, color: AppTheme.pitchGreen)
                if player.isInjured {
                    statusBadge(label: "Injured", color: .red)
                }
                if player.isSuspended {
                    statusBadge(label: "Suspended", color: .red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Morale")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(player.morale)%")
                        .font(.subheadline.bold())
                        .foregroundStyle(player.morale > 60 ? .green : .orange)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private var radarChart: some View {
        VStack(spacing: 8) {
            Text("Attribute Overview")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                radarCategory(label: "TEC", value: player.attributes.technicalAverage)
                radarCategory(label: "PHY", value: player.attributes.physicalAverage)
                radarCategory(label: "MEN", value: player.attributes.mentalAverage)
                radarCategory(label: "GK", value: player.attributes.goalkeepingAverage)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func radarCategory(label: String, value: Double) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(AppTheme.surfaceElevated, lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: value / 99.0)
                    .stroke(AppTheme.ratingColor(Int(value)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value))")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var attributesSection: some View {
        VStack(spacing: 8) {
            Picker("Category", selection: $selectedAttrTab) {
                Text("Technical").tag(0)
                Text("Physical").tag(1)
                Text("Mental").tag(2)
                Text("GK").tag(3)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 4) {
                ForEach(attributesForTab, id: \.name) { attr in
                    attributeRow(name: attr.name, value: attr.value)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private var attributesForTab: [(name: String, value: Int)] {
        let a = player.attributes
        switch selectedAttrTab {
        case 0:
            return [
                ("Ball Control", a.ballControl), ("Crossing", a.crossing), ("Dribbling", a.dribbling),
                ("Finishing", a.finishing), ("Heading", a.heading), ("Long Shots", a.longShots),
                ("Marking", a.marking), ("Passing", a.passing), ("Set Pieces", a.setPieces),
                ("Shot Power", a.shotPower), ("Tackling", a.tackling), ("Technique", a.technique),
                ("Throwing", a.throwing)
            ]
        case 1:
            return [
                ("Acceleration", a.acceleration), ("Agility", a.agility), ("Balance", a.balance),
                ("Jumping", a.jumping), ("Pace", a.pace), ("Stamina", a.stamina),
                ("Strength", a.strength), ("Fitness", a.fitness)
            ]
        case 2:
            return [
                ("Aggression", a.aggression), ("Anticipation", a.anticipation), ("Composure", a.composure),
                ("Concentration", a.concentration), ("Creativity", a.creativity), ("Decisions", a.decisions),
                ("Determination", a.determination), ("Flair", a.flair), ("Leadership", a.leadership),
                ("Positioning", a.positioning), ("Work Rate", a.workRate)
            ]
        default:
            return [
                ("Aerial Ability", a.aerialAbility), ("Command of Area", a.commandOfArea),
                ("Communication", a.communication), ("Handling", a.handling),
                ("Kicking", a.kicking), ("One on Ones", a.oneOnOnes),
                ("Reflexes", a.reflexes), ("Rushing Out", a.rushingOut)
            ]
        }
    }

    private func attributeRow(name: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surfaceElevated)
                        .frame(height: 6)
                    Capsule()
                        .fill(AppTheme.ratingColor(value))
                        .frame(width: geo.size.width * Double(value) / 99.0, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.ratingColor(value))
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Season Stats")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            let s = player.seasonStats
            HStack(spacing: 0) {
                statItem(label: "Apps", value: "\(s.appearances)")
                statItem(label: "Goals", value: "\(s.goals)")
                statItem(label: "Assists", value: "\(s.assists)")
                statItem(label: "Avg Rating", value: s.avgRating > 0 ? String(format: "%.1f", s.avgRating) : "-")
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var contractSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contract")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expires: \(player.contractExpiry)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Wage: €\(player.weeklyWage.formatted())/wk")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Value: €\(formatMoney(player.marketValue))")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func statusBadge(label: String, color: Color) -> some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
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
