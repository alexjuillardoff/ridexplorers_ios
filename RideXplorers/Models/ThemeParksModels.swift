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

// MARK: - Full list endpoint models (/api/theme-parks)

struct ThemeParksListResponse: Decodable {
    let data: [ThemeParksRecord]
}

struct ThemeParksRecord: Decodable, Equatable {
    let id: Int
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let coords: ThemeParksCoords?
}

struct ThemeParksCoords: Decodable, Equatable {
    let lat: String?
    let lng: String?
}
