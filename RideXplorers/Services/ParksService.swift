import Foundation

protocol ParksProviding {
    func fetchParks() async throws -> [QueueTimesPark]
}

struct ParksService: ParksProviding {
    private let parksURL = AppConfig.Endpoints.queueTimesParksURL
    private let themeParksURL = AppConfig.Endpoints.themeParksBaseURL

    func fetchParks() async throws -> [QueueTimesPark] {
        // Use both sources concurrently, then merge and deduplicate
        async let themeResult: [QueueTimesPark]? = try? fetchFromThemeParksAPI()
        async let queueResult: [QueueTimesPark]? = try? fetchFromQueueTimesAPI()
        let theme = await (themeResult ?? [])
        let queue = await (queueResult ?? [])
        let combined = deduplicateParks(theme + queue)
        if !combined.isEmpty { return combined }
        throw URLError(.cannotParseResponse)
    }

    // MARK: - Private helpers
    private func fetchFromQueueTimesAPI() async throws -> [QueueTimesPark] {
        let (data, response) = try await URLSession.shared.data(from: parksURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // API returns an array of groups with nested parks
        if let groups = try? JSONDecoder().decode([QueueTimesParksGroup].self, from: data) {
            return groups.flatMap { $0.parks }
        }

        // Some mirrors return directly an array of parks
        if let parks = try? JSONDecoder().decode([QueueTimesPark].self, from: data) {
            return parks
        }

        // Attempt to unwrap root object
        struct Root: Decodable { let parks: [QueueTimesPark] }
        if let root = try? JSONDecoder().decode(Root.self, from: data) {
            return root.parks
        }

        return []
    }

    private func fetchFromThemeParksAPI() async throws -> [QueueTimesPark] {
        let (data, response) = try await URLSession.shared.data(from: themeParksURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        let payload = try decoder.decode(ThemeParksListResponse.self, from: data)

        let mapped: [QueueTimesPark] = payload.data.compactMap { park in
            guard let coords = park.coords,
                  let latStr = coords.lat, let lngStr = coords.lng,
                  let lat = Double(latStr), let lng = Double(lngStr),
                  lat.isFinite, lng.isFinite else { return nil }
            return QueueTimesPark(
                id: park.id,
                name: park.name,
                slug: nil,
                latitude: lat,
                longitude: lng,
                country: park.country,
                continent: nil
            )
        }

        return mapped
    }

    private func deduplicateParks(_ parks: [QueueTimesPark]) -> [QueueTimesPark] {
        // Combine by normalized name (ignoring generic suffixes) and cluster by proximity
        // to merge entries that refer to the same physical park within ~1km.
        // Keep first occurrence to prefer ThemeParks over QueueTimes (merge order).
        func normalize(_ s: String) -> String {
            let folded = s
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                .replacingOccurrences(of: "[\\p{Punct}]+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let stopwords: Set<String> = [
                "park", "parc", "parque", "resort", "resorts",
                "theme", "amusement", "attractions", "attraction", "le", "la", "les", "the"
            ]
            var tokens = folded.split { $0.isWhitespace }.map { String($0).lowercased() }
            let filtered = tokens.filter { !stopwords.contains($0) }
            tokens = filtered.isEmpty ? tokens : filtered
            while let last = tokens.last, stopwords.contains(last), tokens.count > 1 { tokens.removeLast() }
            return tokens.joined(separator: " ")
        }

        func haversineMeters(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
            let R = 6_371_000.0 // meters
            let dLat = (lat2 - lat1) * .pi / 180
            let dLon = (lon2 - lon1) * .pi / 180
            let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
            let c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return R * c
        }

        let clusterRadiusMeters = 1_000.0 // 1 km: merges entries ~same place (e.g., 200 m apart)

        var keptByName: [String: [QueueTimesPark]] = [:]
        var result: [QueueTimesPark] = []

        for p in parks {
            let nameKey = normalize(p.name)
            var cluster = keptByName[nameKey] ?? []

            var isDuplicate = false
            for q in cluster {
                let dist = haversineMeters(p.latitude, p.longitude, q.latitude, q.longitude)
                if dist <= clusterRadiusMeters {
                    isDuplicate = true
                    break
                }
            }

            if !isDuplicate {
                cluster.append(p)
                keptByName[nameKey] = cluster
                result.append(p)
            }
        }

        return result
    }
}
