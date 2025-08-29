import SwiftUI

private enum NewsSliderConstants {
    /// Intervalle d’auto-défilement du carrousel.
    static let autoSlideInterval: TimeInterval = AppConfig.UI.autoSlideInterval
    /// Hauteur totale d’une carte de news.
    static let cardHeight: CGFloat = AppConfig.UI.sliderCardHeight
    /// Hauteur de l’image dans la carte.
    static let imageHeight: CGFloat = AppConfig.UI.sliderImageHeight
}

struct NewsSliderView: View {
    /// Service des news injecté via l’environnement.
    @EnvironmentObject private var newsService: NewsService
    /// Index courant dans le `TabView` paginé.
    @State private var currentIndex: Int = 0
    /// Élément sélectionné ouvrant la fiche détaillée.
    @State private var selectedNewsItem: NewsItem?

    /// Timer pour l’auto-défilement.
    private let autoSlideTimer = Timer.publish(every: NewsSliderConstants.autoSlideInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsService.shouldShowLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if !newsService.hasData {
                Text("Pas de news disponible")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                GeometryReader { geo in
                    TabView(selection: $currentIndex) {
                        ForEach(Array(newsService.visibleNewsItems.enumerated()), id: \.offset) { index, item in
                            NewsCard(item: item) {
                                selectedNewsItem = item
                            }
                            .frame(width: geo.size.width)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onReceive(autoSlideTimer) { _ in
                        // Met en pause l’auto-défilement si une fiche est ouverte
                        guard selectedNewsItem == nil else { return }
                        guard newsService.visibleNewsItems.count > 1 else { return }
                        withAnimation(.easeInOut) {
                            currentIndex = (currentIndex + 1) % newsService.visibleNewsItems.count
                        }
                    }
                    .onChange(of: newsService.visibleNewsItems.count) { _, newCount in
                        if newCount == 0 { currentIndex = 0 }
                        else if currentIndex >= newCount { currentIndex = 0 }
                    }
                }
                .frame(height: NewsSliderConstants.cardHeight)
            }
        }
        .task {
            if !newsService.hasData { await newsService.fetchNews() }
        }
        .refreshable {
            // Permettre le pull-to-refresh manuel
            await newsService.forceRefresh()
        }
        .sheet(item: $selectedNewsItem) { item in
            NewsDetailView(newsItem: item)
        }
    }
}

private struct NewsCard: View {
    /// Élément de news à afficher.
    let item: NewsItem
    /// Callback déclenché au toucher de la carte.
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Headline (blue, all caps)
            Text(item.headline.uppercased())
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundColor(.blue)

            // Park title
            Text(item.park)
                .font(.title3)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)

            // Location
            Text("\(item.city), \(item.country)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            // Image with gradient and bottom information
            ZStack(alignment: .bottomLeading) {
                let imageHeight: CGFloat = NewsSliderConstants.imageHeight
                Group {
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack { Color.gray.opacity(0.2); ProgressView() }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                ZStack { Color.gray.opacity(0.2); Image(systemName: "photo").foregroundColor(.secondary) }
                            @unknown default:
                                Color.gray.opacity(0.2)
                            }
                        }
                    } else {
                        ZStack { Color.gray.opacity(0.2); Image(systemName: "photo").foregroundColor(.secondary) }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: imageHeight, maxHeight: imageHeight)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, minHeight: imageHeight, maxHeight: imageHeight)
                .clipped()

                // Bottom text on top of gradient
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.rideName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(item.summary)
                        .font(.subheadline)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1))
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct NewsSliderView_Previews: PreviewProvider {
    static var previews: some View {
        NewsSliderView()
            .environmentObject(NewsService.shared)
    }
}
