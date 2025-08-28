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
