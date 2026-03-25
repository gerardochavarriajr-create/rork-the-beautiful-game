import SwiftUI

struct FormationPickerView: View {
    @Bindable var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                formationSelector
                pitchView
                benchSection
            }
            .background(AppTheme.background)
            .navigationTitle("Formation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Auto Fill") {
                        gameManager.autoFillLineup()
                    }
                    .foregroundStyle(AppTheme.pitchGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var formationSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Formation.allFormations) { formation in
                    Button {
                        gameManager.selectedFormation = formation
                        gameManager.lineupPlayerIDs = [:]
                    } label: {
                        Text(formation.name)
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                gameManager.selectedFormation.id == formation.id ? AppTheme.pitchGreen : AppTheme.surfaceElevated,
                                in: Capsule()
                            )
                            .foregroundStyle(gameManager.selectedFormation.id == formation.id ? .white : AppTheme.textSecondary)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
        .padding(.vertical, 12)
    }

    private var pitchView: some View {
        GeometryReader { geo in
            let width = geo.size.width - 32
            let height = width * 1.4

            ZStack {
                pitchBackground(width: width, height: height)

                ForEach(gameManager.selectedFormation.slots) { slot in
                    let x = slot.xPercent * width
                    let y = slot.yPercent * height

                    playerSlot(slot: slot)
                        .position(x: x, y: y)
                }
            }
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity)
        }
        .frame(height: (UIScreen.main.bounds.width - 32) * 1.4)
        .padding(.horizontal, 16)
    }

    private func pitchBackground(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1B5E20"))

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: width * 0.3, height: width * 0.3)
                .position(x: width / 2, y: height / 2)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: width, height: 1)
                .position(x: width / 2, y: height / 2)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: width * 0.5, height: height * 0.15)
                .position(x: width / 2, y: height * 0.07)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: width * 0.5, height: height * 0.15)
                .position(x: width / 2, y: height * 0.93)
        }
    }

    private func playerSlot(slot: FormationSlot) -> some View {
        let playerID = gameManager.lineupPlayerIDs[slot.id]
        let player = playerID.flatMap { id in gameManager.userClub?.players.first { $0.id == id } }

        return VStack(spacing: 2) {
            Circle()
                .fill(player != nil ? AppTheme.positionColor(slot.position.category) : Color.white.opacity(0.2))
                .frame(width: 38, height: 38)
                .overlay {
                    if let player {
                        Text("\(player.overallRating)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Text(slot.position.rawValue)
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

            Text(player?.lastName ?? slot.position.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 60)
        }
    }

    private var benchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Substitutes")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 16)

            let assignedIDs = Set(gameManager.lineupPlayerIDs.values)
            let bench = gameManager.userClub?.players
                .filter { !assignedIDs.contains($0.id) && !$0.isInjured && !$0.isSuspended }
                .sorted { $0.overallRating > $1.overallRating }
                .prefix(7) ?? []

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(bench)) { player in
                        VStack(spacing: 4) {
                            Text("\(player.overallRating)")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.ratingColor(player.overallRating))
                            Text(player.lastName)
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text(player.primaryPosition.rawValue)
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 6)
                        .background(AppTheme.surface, in: .rect(cornerRadius: 8))
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 10)
    }
}
