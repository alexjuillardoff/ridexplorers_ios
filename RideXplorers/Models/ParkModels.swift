import Foundation

/// Groupe de parcs tel que renvoyé par l’API Queue-Times.
struct QueueTimesParksGroup: Decodable, Equatable {
    /// Nom du groupe (ex: pays/continent), parfois `nil`.
    let name: String?
    /// Liste des parcs dans ce groupe.
    let parks: [QueueTimesPark]
}

/// Représente un parc (Queue-Times ou mappé depuis ThemeParks API).
struct QueueTimesPark: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let slug: String?
    let latitude: Double
    let longitude: Double
    let country: String?
    let continent: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case latitude
        case longitude
        case country
        case continent
        // Fallback keys sometimes used by APIs
        case lat
        case lng
        case lon
    }

    /// Initialisateur direct (utile lors du mapping depuis d’autres APIs).
    init(id: Int, name: String, slug: String?, latitude: Double, longitude: Double, country: String?, continent: String?) {
        self.id = id
        self.name = name
        self.slug = slug
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.continent = continent
    }

    /// Décodage tolérant pour lat/lng (accepte number ou string, et clés alternatives).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try? container.decodeIfPresent(String.self, forKey: .slug)

        // Decode latitude/longitude accepting either number or string, and fallback keys
        func decodeCoordinate(for key: CodingKeys, fallbackKeys: [CodingKeys]) throws -> Double {
            if let doubleValue = try? container.decode(Double.self, forKey: key) { return doubleValue }
            if let stringValue = try? container.decode(String.self, forKey: key), let parsed = Double(stringValue) { return parsed }
            for fallback in fallbackKeys {
                if let doubleValue = try? container.decode(Double.self, forKey: fallback) { return doubleValue }
                if let stringValue = try? container.decode(String.self, forKey: fallback), let parsed = Double(stringValue) { return parsed }
            }
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Missing coordinate for \(key.rawValue)"))
        }

        latitude = try decodeCoordinate(for: .latitude, fallbackKeys: [.lat])
        longitude = try decodeCoordinate(for: .longitude, fallbackKeys: [.lng, .lon])

        country = try? container.decodeIfPresent(String.self, forKey: .country)
        continent = try? container.decodeIfPresent(String.self, forKey: .continent)
    }
}

/// Entrée de parc enrichie de la distance à l’utilisateur.
struct NearbyPark: Identifiable, Equatable {
    let id: Int
    let name: String
    let distanceMeters: Double
    let country: String?
}

