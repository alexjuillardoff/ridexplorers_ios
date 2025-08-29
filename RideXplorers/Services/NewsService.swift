import Foundation

@MainActor
final class NewsService: ObservableObject {
    /// Singleton du service de news (thread principal).
    static let shared = NewsService()

    /// Liste complète des éléments de news (y compris non visibles).
    @Published var newsItems: [NewsItem] = []
    /// Indique si une récupération réseau est en cours.
    @Published var isLoading = false
    /// Horodatage de la dernière mise à jour réussie.
    @Published var lastUpdateTime: Date?
    /// Indique si le cache initial a été chargé (mémoire prête).
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
    /// Charge les news et le timestamp depuis `UserDefaults` si disponibles.
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

    /// Persiste les news et met à jour `lastUpdateTime`.
    private func saveToCache(_ news: [NewsItem]) {
        if let data = try? JSONEncoder().encode(news) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastUpdateKey)
            lastUpdateTime = now
        }
    }

    // MARK: - Auto Refresh
    /// Programme un rafraîchissement automatique périodique.
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.News.refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.refreshNewsIfNeeded() }
        }
    }

    /// Déclenche un rafraîchissement si l’intervalle est écoulé.
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
    /// Récupère les news depuis l’API, met à jour l’état et le cache.
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

    /// Force un rafraîchissement immédiat (ignore l’intervalle).
    func forceRefresh() async { await fetchNews() }

    // MARK: - Cache Status
    /// Indique si le cache est encore valide selon l’intervalle défini.
    var isCacheValid: Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < AppConfig.News.refreshInterval
    }

    /// Temps restant avant le prochain rafraîchissement automatique.
    var timeUntilNextRefresh: TimeInterval {
        guard let lastUpdate = lastUpdateTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastUpdate)
        return max(0, AppConfig.News.refreshInterval - elapsed)
    }

    // MARK: - Data Availability
    /// Indique si des données visibles sont disponibles et initialisées.
    var hasData: Bool { !visibleNewsItems.isEmpty && isInitialized }
    /// Indique si l’UI doit afficher un loader (initial fetch).
    var shouldShowLoading: Bool { isLoading && visibleNewsItems.isEmpty }

    // Derived data
    /// Filtre les éléments visibles.
    var visibleNewsItems: [NewsItem] { newsItems.filter { $0.visible } }
}
