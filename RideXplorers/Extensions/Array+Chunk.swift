import Foundation

extension Array {
    /// Splits the array into consecutive chunks of the given size.
    /// If `size` <= 0, returns an empty array.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start ..< Swift.min(start + size, count)])
        }
    }
}

