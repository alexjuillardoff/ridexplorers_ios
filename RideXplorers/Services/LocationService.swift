import Foundation
import CoreLocation

@MainActor
protocol LocationProviding: AnyObject {
    /// Statut d’autorisation de la localisation.
    var authorizationStatus: CLAuthorizationStatus { get }
    /// Demande l’autorisation "Quand l’app est active".
    func requestWhenInUseAuthorization()
    /// Retourne la localisation courante (peut suspendre jusqu’à réception).
    func currentLocation() async throws -> CLLocation
}

@MainActor
final class LocationService: NSObject, ObservableObject, LocationProviding {
    /// Gestionnaire Core Location sous-jacent.
    private let manager = CLLocationManager()
    /// Continuation utilisée pour reprendre `currentLocation()` à la réception.
    private var continuation: CheckedContinuation<CLLocation, Error>?

    /// Statut exposé et observable pour l’UI.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Tente de retourner immédiatement la dernière localisation connue sinon attend une mise à jour.
    func currentLocation() async throws -> CLLocation {
        if let location = manager.location {
            return location
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.continuation = continuation
            self.manager.requestLocation()
        }
    }
}

@MainActor
extension LocationService: @preconcurrency CLLocationManagerDelegate {
    /// Réagit aux changements d’autorisation et déclenche une mise à jour si autorisé.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    /// Reprend la continuation avec la dernière position reçue.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        continuation?.resume(returning: location)
        continuation = nil
    }

    /// Reprend la continuation avec une erreur en cas d’échec.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
