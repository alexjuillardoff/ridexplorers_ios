import SwiftUI

struct ContentView: View {
    /// Vue d’accueil qui présente l’onglet principal.
    var body: some View {
        TabBarView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NewsService.shared)
    }
}
