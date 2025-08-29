import SwiftUI
import UIKit

extension Data {
    /// Convertit des données d’image en `UIImage`.
    func toUIImage() -> UIImage? {
        return UIImage(data: self)
    }
}

extension UIImage {
    /// Convertit une `UIImage` en `Image` (SwiftUI).
    func toSwiftUIImage() -> Image {
        return Image(uiImage: self)
    }
}
