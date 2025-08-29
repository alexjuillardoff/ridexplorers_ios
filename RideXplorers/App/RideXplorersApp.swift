import SwiftUI

@main
struct RideXplorersApp: App {
    /// Point d’entrée principal de l’application.
    /// Configure la hiérarchie initiale de vues et
    /// injecte les services partagés via l’environnement.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NewsService.shared)
        }
    }
}
