import Foundation

struct ThemeParksSearchResponse: Decodable {
    let themeParks: [ThemePark]
}

struct ThemePark: Decodable, Equatable {
    let id: Int?
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let mainPicture: ThemeParkPicture?
    let pictures: [ThemeParkPicture]?
}

struct ThemeParkPicture: Decodable, Equatable {
    let id: Int?
    let name: String?
    let url: String?
    let copyName: String?
    let copyDate: String?
}
