import Foundation

final class NewsService {
    static let shared = NewsService()
    private init() {}

    private let url = URL(string: "https://free.alexjuillard.fr:8000/blog/news")!

    func fetchNews() async throws -> [NewsItem] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode([NewsItem].self, from: data)
    }
}
