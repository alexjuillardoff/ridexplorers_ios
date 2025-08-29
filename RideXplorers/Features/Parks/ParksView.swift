import SwiftUI

struct ParksView: View {
    /// Écran d’accueil pour les parcs :
    /// affiche le carrousel de news puis la liste des parcs proches.
    var body: some View {
        PageView(title: "Parks") {
            VStack(spacing: 0) {
                NewsSliderView()
                    .padding(.top, -20)
                NearbyParksListView()
                    .padding(.top, -20)
                Spacer(minLength: 0)
            }
        }
    }
}

struct ParksView_Previews: PreviewProvider {
    static var previews: some View {
        ParksView()
            .environmentObject(NewsService.shared)
    }
}
