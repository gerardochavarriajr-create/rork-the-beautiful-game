import SwiftUI

struct LeagueTableView: View {
    let gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(gameManager.leagueTable.enumerated()), id: \.element.id) { index, row in
                        tableRow(position: index + 1, row: row)
                        if index < gameManager.leagueTable.count - 1 {
                            Divider().background(AppTheme.surfaceElevated)
                        }
                    }
                }
                .background(AppTheme.surface, in: .rect(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("League Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 28, alignment: .center)
            Text("Team").frame(maxWidth: .infinity, alignment: .leading)
            Text("P").frame(width: 26, alignment: .center)
            Text("W").frame(width: 26, alignment: .center)
            Text("D").frame(width: 26, alignment: .center)
            Text("L").frame(width: 26, alignment: .center)
            Text("GD").frame(width: 32, alignment: .center)
            Text("Pts").frame(width: 32, alignment: .center)
        }
        .font(.caption2.bold())
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(AppTheme.surfaceElevated)
    }

    private func tableRow(position: Int, row: LeagueTableRow) -> some View {
        HStack(spacing: 0) {
            Text("\(position)")
                .frame(width: 28, alignment: .center)
                .font(.caption.bold())

            HStack(spacing: 6) {
                let club = gameManager.league?.clubs.first { $0.name == row.teamName }
                Circle()
                    .fill(Color(hex: club?.primaryColor ?? "#333"))
                    .frame(width: 18, height: 18)

                Text(row.teamName)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.caption.bold())

            Text("\(row.played)").frame(width: 26, alignment: .center).font(.caption)
            Text("\(row.won)").frame(width: 26, alignment: .center).font(.caption)
            Text("\(row.drawn)").frame(width: 26, alignment: .center).font(.caption)
            Text("\(row.lost)").frame(width: 26, alignment: .center).font(.caption)
            Text("\(row.goalDifference > 0 ? "+" : "")\(row.goalDifference)")
                .frame(width: 32, alignment: .center).font(.caption)
            Text("\(row.points)")
                .frame(width: 32, alignment: .center)
                .font(.caption.bold())
        }
        .foregroundStyle(row.isUserTeam ? AppTheme.pitchGreen : AppTheme.textPrimary)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(row.isUserTeam ? AppTheme.pitchGreen.opacity(0.08) : .clear)
    }
}
