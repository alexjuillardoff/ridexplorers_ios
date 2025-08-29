import SwiftUI

struct SearchView: View {
    /// Onglet "Search" (placeholder pour une recherche globale à venir).
    var body: some View {
        PageView(title: "Search") {
            Spacer()
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
