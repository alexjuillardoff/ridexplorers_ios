import SwiftUI

extension Data {
    func toUIImage() -> UIImage? {
        return UIImage(data: self)
    }
}

extension UIImage {
    func toSwiftUIImage() -> Image {
        return Image(uiImage: self)
    }
}
