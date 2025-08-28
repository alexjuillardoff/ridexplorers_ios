import SwiftUI

struct NewsSliderView: View {
    @StateObject private var newsService = NewsService.shared
    @State private var currentIndex: Int = 0
    private let autoSlideTimer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if newsService.visibleNewsItems.isEmpty {
                Text("Pas de news disponible")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                GeometryReader { geo in
                    TabView(selection: $currentIndex) {
                        ForEach(Array(newsService.visibleNewsItems.enumerated()), id: \.offset) { index, item in
                            NewsCard(item: item)
                                .frame(width: geo.size.width)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onReceive(autoSlideTimer) { _ in
                        guard !newsService.visibleNewsItems.isEmpty else { return }
                        withAnimation(.easeInOut) {
                            currentIndex = (currentIndex + 1) % newsService.visibleNewsItems.count
                        }
                    }
                }
                .frame(height: 360)
            }
        }
        .task {
            // Charger les news au démarrage
            await newsService.fetchNews()
        }
        .refreshable {
            // Permettre le pull-to-refresh manuel
            await newsService.forceRefresh()
        }
        .onAppear {
            // Plus besoin de logique de filtrage ici
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading) {
            // Headline (blue, all caps)
            Text(item.main_news.uppercased())
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundColor(.blue)

            // Park title
            Text(item.parks)
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
                let imageHeight: CGFloat = 200
                Group {
                    if let urlString = item.pictures, let url = URL(string: urlString) {
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
                    Text(item.ride)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(item.description)
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
    }
}

struct NewsSliderView_Previews: PreviewProvider {
    static var previews: some View {
        NewsSliderView()
    }
}
