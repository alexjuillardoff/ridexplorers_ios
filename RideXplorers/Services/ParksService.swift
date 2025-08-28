import Foundation

protocol ParksProviding {
    func fetchParks() async throws -> [QueueTimesPark]
}

struct ParksService: ParksProviding {
    private let parksURL = URL(string: "https://queue-times.com/parks.json")!

    func fetchParks() async throws -> [QueueTimesPark] {
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

        throw URLError(.cannotParseResponse)
    }
}


