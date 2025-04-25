import SwiftUI
import CoreData

@main
struct CricketScoreCardApp: App {
    // single Core Data container for the whole app
    private let container = PersistenceController.shared
    
    init() {
        // give repository its live context once
        CricketDataRepository.shared.useContext(container.viewContext)
        
        // seed three demo matches if none exist
        if (try? container.viewContext.count(for: Match.fetchRequest())) == 0 {
            CricketDataRepository.shared.resetAndSeedDemoData()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, container.viewContext)
        }
    }
}
