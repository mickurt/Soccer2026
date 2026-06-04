
import SwiftUI
import SwiftData

@main
struct WorldCup2026App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Match.self,
            Team.self,
            Venue.self
        ])
        let modelConfiguration = ModelConfiguration("WorldCupDB_v2", schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DataSeeder.shared.seed(context: sharedModelContainer.mainContext)
                    DataSeeder.shared.startPollingUpdates(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
