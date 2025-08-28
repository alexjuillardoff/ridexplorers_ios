import Foundation

struct NewsItem: Identifiable, Decodable, Encodable, Equatable {
    let id: Int
    let visible: Bool
    let headline: String
    let park: String
    let city: String
    let country: String
    let rideName: String
    let summary: String
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id = "id_news"
        case visible
        case headline = "main_news"
        case park = "parks"
        case city
        case country
        case rideName = "ride"
        case summary = "description"
        case imageURL = "pictures"
    }
}
