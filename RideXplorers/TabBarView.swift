import SwiftUI

struct TabBarView: View {
    @SceneStorage("selectedTab") private var selectedTabIndex = 0
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab("Parks", systemImage: "leaf", value: 0) {
                // content
            }

            Tab("Ride", systemImage: "bicycle", value: 0) {
                // content
            }

            Tab("Stats", systemImage: "chart.bar", value: 0) {
                // content
            }

            Tab("search", systemImage: "magnifyingglass", value: 0, role: .search) {
                // content
            }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}


