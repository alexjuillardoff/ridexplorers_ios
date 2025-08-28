import Foundation
import CoreLocation

@MainActor
final class NearbyParksViewModel: ObservableObject {
    @Published var nearbyParks: [NearbyPark] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let parksProvider: ParksProviding
    private let locationProvider: LocationProviding

    init(parksProvider: ParksProviding? = nil, locationProvider: LocationProviding? = nil) {
        self.parksProvider = parksProvider ?? ParksService()
        self.locationProvider = locationProvider ?? LocationService()
    }

    func loadTopNearestParks(limit: Int = 5) async {
        isLoading = true
        errorMessage = nil
        do {
            if locationProvider.authorizationStatus == .notDetermined {
                locationProvider.requestWhenInUseAuthorization()
            }

            let location = try await locationProvider.currentLocation()
            let parks = try await parksProvider.fetchParks()

            let items: [NearbyPark] = parks.map { park in
                let distance = Self.distanceMeters(from: location.coordinate, to: CLLocationCoordinate2D(latitude: park.latitude, longitude: park.longitude))
                return NearbyPark(id: park.id, name: park.name, distanceMeters: distance, country: park.country)
            }
            .sorted(by: { $0.distanceMeters < $1.distanceMeters })
            .prefix(limit)
            .map { $0 }

            nearbyParks = items
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private static func distanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2)
    }
}


