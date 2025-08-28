import Foundation

struct NewsItem: Identifiable, Decodable {
    let id: Int
    let visible: Bool
    let main_news: String
    let parks: String
    let city: String
    let country: String
    let ride: String
    let description: String
    let pictures: String?

    enum CodingKeys: String, CodingKey {
        case id = "id_news"
        case visible
        case main_news
        case parks
        case city
        case country
        case ride
        case description
        case pictures
    }
}

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


