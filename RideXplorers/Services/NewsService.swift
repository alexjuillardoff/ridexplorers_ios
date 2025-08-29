import Foundation

@MainActor
final class NewsService: ObservableObject {
    static let shared = NewsService()

    @Published var newsItems: [NewsItem] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var isInitialized = false

    private let cacheKey = "cached_news"
    private let lastUpdateKey = "last_news_update"

    private var refreshTimer: Timer?

    private init() {
        loadCachedNews()
        startAutoRefresh()

        // Charger les données immédiatement si pas de cache
        if visibleNewsItems.isEmpty {
            Task { await fetchNews() }
        }
    }

    deinit { refreshTimer?.invalidate() }

    // MARK: - Cache Management
    private func loadCachedNews() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedNews = try? JSONDecoder().decode([NewsItem].self, from: data) {
            newsItems = cachedNews
            isInitialized = true
        }

        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTime = lastUpdate
        }
    }

    private func saveToCache(_ news: [NewsItem]) {
        if let data = try? JSONEncoder().encode(news) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastUpdateKey)
            lastUpdateTime = now
        }
    }

    // MARK: - Auto Refresh
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.News.refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.refreshNewsIfNeeded() }
        }
    }

    private func refreshNewsIfNeeded() async {
        guard let lastUpdate = lastUpdateTime else {
            await fetchNews(); return
        }
        let elapsed = Date().timeIntervalSince(lastUpdate)
        if elapsed >= AppConfig.News.refreshInterval {
            await fetchNews()
        }
    }

    // MARK: - Public Methods
    func fetchNews() async {
        isLoading = true
        do {
            let (data, response) = try await URLSession.shared.data(from: AppConfig.Endpoints.newsURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let news = try JSONDecoder().decode([NewsItem].self, from: data)
            newsItems = news
            isLoading = false
            isInitialized = true
            saveToCache(news)
        } catch {
            isLoading = false
            #if DEBUG
            print("Erreur lors de la récupération des news: \(error)")
            #endif
        }
    }

    func forceRefresh() async { await fetchNews() }

    // MARK: - Cache Status
    var isCacheValid: Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < AppConfig.News.refreshInterval
    }

    var timeUntilNextRefresh: TimeInterval {
        guard let lastUpdate = lastUpdateTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastUpdate)
        return max(0, AppConfig.News.refreshInterval - elapsed)
    }

    // MARK: - Data Availability
    var hasData: Bool { !visibleNewsItems.isEmpty && isInitialized }
    var shouldShowLoading: Bool { isLoading && visibleNewsItems.isEmpty }

    // Derived data
    var visibleNewsItems: [NewsItem] { newsItems.filter { $0.visible } }
}
