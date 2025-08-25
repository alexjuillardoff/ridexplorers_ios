import SwiftUI

struct TabBarView: View {
    @SceneStorage("selectedTab") private var selectedTabIndex = 0
    
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
    let title: String
    let systemImage: String
    let value: Int
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
    }
}


