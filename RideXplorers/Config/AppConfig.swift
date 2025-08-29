import Foundation
import CoreGraphics

/// Centralized application configuration (URLs, timings, feature flags).
enum AppConfig {
    enum Endpoints {
        // Content APIs
        static let newsURL = URL(string: "https://free.alexjuillard.fr:8000/blog/news")!
        static let queueTimesParksURL = URL(string: "https://queue-times.com/parks.json")!
        static let themeParksBaseURL = URL(string: "https://free.alexjuillard.fr:8000/api/theme-parks")!
        static let themeParksSearchURL = URL(string: "https://free.alexjuillard.fr:8000/api/theme-parks/search")!
        static let rcdbBaseURL = URL(string: "https://rcdb.com")!
    }

    enum News {
        /// Auto-refresh period for news (seconds)
        static let refreshInterval: TimeInterval = 5 * 60
    }

    enum UI {
        /// Default card height for slider-based cards
        static let sliderCardHeight: CGFloat = 360
        /// Default image height inside slider cards
        static let sliderImageHeight: CGFloat = 200
        /// Auto slide interval for carousels (seconds)
        static let autoSlideInterval: TimeInterval = 7
    }
}
