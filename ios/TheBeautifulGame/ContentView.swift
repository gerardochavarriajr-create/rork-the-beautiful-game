import SwiftUI

struct ContentView: View {
    @State private var gameManager = GameManager()

    var body: some View {
        Group {
            if gameManager.phase == .onboarding {
                OnboardingView(gameManager: gameManager)
            } else {
                mainTabView
            }
        }
        .task {
            let _ = gameManager.load()
        }
    }

    private var mainTabView: some View {
        TabView(selection: Binding(
            get: { gameManager.selectedTab },
            set: { gameManager.selectedTab = $0 }
        )) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                DashboardView(gameManager: gameManager)
            }

            Tab("Squad", systemImage: "person.3.fill", value: 1) {
                SquadListView(gameManager: gameManager)
            }

            Tab("Match", systemImage: "sportscourt.fill", value: 2) {
                MatchTabView(gameManager: gameManager)
            }

            Tab("Transfers", systemImage: "arrow.left.arrow.right", value: 3) {
                TransferHubView(gameManager: gameManager)
            }

            Tab("Club", systemImage: "building.2.fill", value: 4) {
                ClubOverviewView(gameManager: gameManager)
            }
        }
        .tint(AppTheme.pitchGreen)
        .preferredColorScheme(.dark)
    }
}
