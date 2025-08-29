import SwiftUI

struct TabBarView: View {
    /// Indice de l’onglet sélectionné, persisté par scène.
    @SceneStorage("selectedTab") private var selectedTabIndex = 0
    
    /// Définition des onglets disponibles dans l’application.
    private let tabs = [
        TabItem(title: "Parks", systemImage: "leaf", value: 0),
        TabItem(title: "Ride", systemImage: "bicycle", value: 1),
        TabItem(title: "Stats", systemImage: "chart.bar", value: 2),
        TabItem(title: "Search", systemImage: "magnifyingglass", value: 3, role: .search)
    ]
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(tabs, id: \.value) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab.value, role: tab.role) {
                    destinationView(for: tab.value)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for tabIndex: Int) -> some View {
        /// Retourne la vue correspondant à l’onglet donné.
        switch tabIndex {
        case 0: ParksView()
        case 1: RideView()
        case 2: StatsView()
        case 3: SearchView()
        default: ParksView()
        }
    }
}

private struct TabItem {
    /// Titre lisible par l’utilisateur.
    let title: String
    /// Nom SF Symbol pour l’icône d’onglet.
    let systemImage: String
    /// Valeur utilisée comme `tag` pour la sélection.
    let value: Int
    /// Rôle optionnel de l’onglet (ex. `.search`).
    let role: TabRole?
    
    init(title: String, systemImage: String, value: Int, role: TabRole? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
        self.role = role
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .environmentObject(NewsService.shared)
    }
}
