import Foundation

final class NewsService: ObservableObject {
    static let shared = NewsService()
    
    @Published var newsItems: [NewsItem] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var isInitialized = false
    
    private let url = URL(string: "https://free.alexjuillard.fr:8000/blog/news")!
    private let cacheKey = "cached_news"
    private let lastUpdateKey = "last_news_update"
    private let refreshInterval: TimeInterval = 300 // 5 minutes en secondes
    
    private var refreshTimer: Timer?
    
    private init() {
        loadCachedNews()
        startAutoRefresh()
        
        // Charger les données immédiatement si pas de cache
        if visibleNewsItems.isEmpty {
            Task {
                await fetchNews()
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Cache Management
    
    private func loadCachedNews() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedNews = try? JSONDecoder().decode([NewsItem].self, from: data) {
            self.newsItems = cachedNews
            self.isInitialized = true
        }
        
        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            self.lastUpdateTime = lastUpdate
        }
    }
    
    private func saveToCache(_ news: [NewsItem]) {
        if let data = try? JSONEncoder().encode(news) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            self.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshNewsIfNeeded()
            }
        }
    }
    
    private func refreshNewsIfNeeded() async {
        // Vérifier si on a besoin de rafraîchir
        guard let lastUpdate = lastUpdateTime else {
            await fetchNews()
            return
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate >= refreshInterval {
            await fetchNews()
        }
    }
    
    // MARK: - Public Methods
    
    func fetchNews() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let news = try decoder.decode([NewsItem].self, from: data)
            
            await MainActor.run {
                self.newsItems = news
                self.isLoading = false
                self.isInitialized = true
                self.saveToCache(news)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Erreur lors de la récupération des news: \(error)")
            }
        }
    }
    
    func forceRefresh() async {
        await fetchNews()
    }
    
    // MARK: - Cache Status
    
    var isCacheValid: Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < refreshInterval
    }
    
    var timeUntilNextRefresh: TimeInterval {
        guard let lastUpdate = lastUpdateTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastUpdate)
        return max(0, refreshInterval - elapsed)
    }
    
    // MARK: - Data Availability
    
    var hasData: Bool {
        return !visibleNewsItems.isEmpty && isInitialized
    }
    
    var shouldShowLoading: Bool {
        return isLoading && visibleNewsItems.isEmpty
    }

    // Derived data
    var visibleNewsItems: [NewsItem] {
        newsItems.filter { $0.visible }
    }
}
