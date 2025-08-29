import Foundation

/// Réponse de recherche ThemeParks (endpoint `/api/theme-parks/search`).
struct ThemeParksSearchResponse: Decodable {
    let themeParks: [ThemePark]
}

/// Modèle de parc depuis ThemeParks API.
struct ThemePark: Decodable, Equatable {
    let id: Int?
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let mainPicture: ThemeParkPicture?
    let pictures: [ThemeParkPicture]?
}

/// Modèle d’image associé à un parc ThemeParks.
struct ThemeParkPicture: Decodable, Equatable {
    let id: Int?
    let name: String?
    let url: String?
    let copyName: String?
    let copyDate: String?
}

// MARK: - Full list endpoint models (/api/theme-parks)

/// Réponse paginée de la liste de parcs (endpoint `/api/theme-parks`).
struct ThemeParksListResponse: Decodable {
    let data: [ThemeParksRecord]
}

/// Enregistrement individuel de parc pour la liste complète.
struct ThemeParksRecord: Decodable, Equatable {
    let id: Int
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let coords: ThemeParksCoords?
}

/// Coordonnées lat/lng renvoyées sous forme de chaînes.
struct ThemeParksCoords: Decodable, Equatable {
    let lat: String?
    let lng: String?
}
