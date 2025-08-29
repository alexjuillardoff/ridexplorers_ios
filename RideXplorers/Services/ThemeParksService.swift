import Foundation

/// Cache en mémoire (acteur) pour mémoriser les URLs d’images par nom de parc.
actor ThemeParksImageCache {
    private var map: [String: URL] = [:]

    func value(for key: String) -> URL? { map[key] }
    func set(_ url: URL, for key: String) { map[key] = url }
}

/// Service réseau pour interroger l’API ThemeParks et construire
/// des URLs d’images (absolues) à partir des résultats.
final class ThemeParksService {
    static let shared = ThemeParksService()

    private let baseSearchURL = AppConfig.Endpoints.themeParksSearchURL
    private let rcdbBase = AppConfig.Endpoints.rcdbBaseURL
    private let cache = ThemeParksImageCache()

    private init() {}

    /// Retourne l’URL de la première image (principale) pour un parc.
    func mainPictureURL(for parkName: String) async throws -> URL? {
        if let cached = await cache.value(for: normalizedKey(parkName)) { return cached }
        let parks = try await searchThemeParks(query: parkName)
        guard !parks.isEmpty else { return nil }
        let best = bestMatch(for: parkName, in: parks)
        guard let path = best.mainPicture?.url, let url = buildImageURL(from: path) else { return nil }
        await cache.set(url, for: normalizedKey(parkName))
        return url
    }

    /// Retourne jusqu’à `limit` URLs d’images (principale + autres) pour un parc.
    func pictureURLs(for parkName: String, limit: Int = 3) async throws -> [URL] {
        let parks = try await searchThemeParks(query: parkName)
        guard !parks.isEmpty else { return [] }

        // Choose best match via fuzzy scoring
        let best = bestMatch(for: parkName, in: parks)
        var urls: [URL] = []

        // mainPicture first
        if let main = best.mainPicture?.url, let u = buildImageURL(from: main) {
            urls.append(u)
        }
        // then additional pictures
        if let others = best.pictures {
            for pic in others {
                guard let path = pic.url, let u = buildImageURL(from: path) else { continue }
                if !urls.contains(u) { urls.append(u) }
                if urls.count >= limit { break }
            }
        }

        return Array(urls.prefix(limit))
    }

    // MARK: - Networking
    /// Interroge l’endpoint de recherche ThemeParks avec la requête donnée.
    private func searchThemeParks(query: String) async throws -> [ThemePark] {
        guard var components = URLComponents(url: baseSearchURL, resolvingAgainstBaseURL: false) else { return [] }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return [] }
        let payload = try JSONDecoder().decode(ThemeParksSearchResponse.self, from: data)
        return payload.themeParks
    }

    // MARK: - Matching helpers
    /// Construit une URL absolue à partir d’un chemin ou d’une URL potentiellement relative.
    private func buildImageURL(from pathOrURL: String) -> URL? {
        if let absolute = URL(string: pathOrURL), absolute.scheme != nil { return absolute }
        let trimmed = pathOrURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return rcdbBase.appendingPathComponent(trimmed)
    }

    /// Sélectionne le meilleur match parmi les candidats en combinant exactitude,
    /// inclusion de tokens, Jaccard et Levenshtein.
    private func bestMatch(for query: String, in parks: [ThemePark]) -> ThemePark {
        // If an exact case-insensitive match exists, use it
        if let exact = parks.first(where: { $0.name.caseInsensitiveCompare(query) == .orderedSame }) {
            return exact
        }

        let qNorm = normalize(query)
        // Prefer candidates whose normalized name contains the query
        if let contained = parks.first(where: { normalize($0.name).contains(qNorm) }) {
            return contained
        }

        // Prefer candidates that contain all query tokens
        let qTokens = tokenSet(query)
        let subsetCandidates = parks.filter { tokenSet($0.name).isSuperset(of: qTokens) }
        if let bestSubset = subsetCandidates.max(by: {
            jaccard(tokenSet($0.name), qTokens) < jaccard(tokenSet($1.name), qTokens)
        }) { return bestSubset }

        // Score all candidates
        let scored = parks.map { park in
            (park, fuzzyScore(between: query, and: park.name))
        }
        .sorted { $0.1 > $1.1 }
        // If top is good enough, use it; otherwise fallback to first
        let threshold = 0.45
        if let top = scored.first, top.1 >= threshold { return top.0 }
        return parks.first!
    }

    private func normalizedKey(_ s: String) -> String {
        normalize(s)
    }

    /// Normalise une chaîne pour comparaisons: suppression d’accents/casse, découpage,
    /// suppression des stopwords, puis jonction par espace.
    private func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let replacedSeparators = folded.replacingOccurrences(of: "[\\p{Punct}]+", with: " ", options: .regularExpression)
        let tokens = replacedSeparators
            .split{ $0.isWhitespace }
            .map { String($0).lowercased() }
            .filter { !stopwords.contains($0) }
        return tokens.joined(separator: " ")
    }

    /// Transforme une chaîne normalisée en ensemble de tokens.
    private func tokenSet(_ s: String) -> Set<String> {
        Set(normalize(s).split(separator: " ").map(String.init))
    }

    /// Similarité de Jaccard entre deux ensembles de tokens.
    private func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        if a.isEmpty && b.isEmpty { return 1.0 }
        let inter = a.intersection(b).count
        let uni = a.union(b).count
        return uni == 0 ? 0 : Double(inter) / Double(uni)
    }

    /// Ratio de similarité basé sur la distance de Levenshtein.
    private func levenshteinRatio(_ a: String, _ b: String) -> Double {
        let s1 = normalize(a)
        let s2 = normalize(b)
        if s1 == s2 { return 1.0 }
        let d = levenshteinDistance(s1, s2)
        let maxLen = max(s1.count, s2.count)
        if maxLen == 0 { return 1.0 }
        return 1.0 - Double(d) / Double(maxLen)
    }

    /// Score fuzzy combinant Jaccard et Levenshtein (pondération 65/35).
    private func fuzzyScore(between a: String, and b: String) -> Double {
        let tsA = tokenSet(a)
        let tsB = tokenSet(b)
        let j = jaccard(tsA, tsB)
        let l = levenshteinRatio(a, b)
        // Weighted combination
        return 0.65 * j + 0.35 * l
    }

    /// Distance de Levenshtein entre deux chaînes.
    private func levenshteinDistance(_ aStr: String, _ bStr: String) -> Int {
        let a = Array(aStr)
        let b = Array(bStr)
        let n = a.count
        let m = b.count
        if n == 0 { return m }
        if m == 0 { return n }

        var prev = Array(0...m)
        var curr = Array(repeating: 0, count: m + 1)
        for i in 1...n {
            curr[0] = i
            for j in 1...m {
                let cost = (a[i-1] == b[j-1]) ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,           // deletion
                    curr[j-1] + 1,         // insertion
                    prev[j-1] + cost       // substitution
                )
            }
            swap(&prev, &curr)
        }
        return prev[m]
    }

    private let stopwords: Set<String> = [
        // Generic terms
        "park", "theme", "amusement", "resort", "world", "studio", "studios", "ride", "rides",
        // Articles / prepositions (fr/en)
        "the", "a", "an", "le", "la", "les", "de", "du", "des", "d", "et", "au", "aux", "à",
        // Connectors
        "-"
    ]
}
