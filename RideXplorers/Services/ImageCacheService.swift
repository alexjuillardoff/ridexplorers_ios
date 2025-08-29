import Foundation
import UIKit

/// Service de cache disque pour images de parcs ThemeParks.
/// Télécharge, redimensionne (carré) et compresse avant stockage.
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let fileManager = FileManager.default
    private let directoryName = "ThemeParkImages"

    // Compression settings
    private let compressionQuality: CGFloat = 0.75
    private let targetMaxDimension: CGFloat = 150 // square px (sufficient for 50x50 @3x)

    private init() {
        try? ensureDirectoryExists()
    }

    /// Retourne l’URL de fichier local pour l’image principale d’un parc (télécharge si besoin).
    func localMainImageURL(for parkName: String) async -> URL? {
        let key = makeKey(parkName)
        // 1) Existing cached main image
        if let existing = existingLocalFiles(forKey: key, limit: 1).first { return existing }

        // 2) Fetch main picture only
        guard let remoteURL = try? await ThemeParksService.shared.mainPictureURL(for: parkName) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let image = UIImage(data: data) else { return nil }
            let processed = await downscaleAndCompress(image: image)
            let fileURL = try store(data: processed, key: key, index: 0)
            return fileURL
        } catch {
            return nil
        }
    }

    /// Retourne une liste d’URLs locales pour jusqu’à `limit` images du parc.
    func localImageURLs(for parkName: String, limit: Int = 4) async -> [URL] {
        let key = makeKey(parkName)
        // 1) Read existing cached files
        let cached = existingLocalFiles(forKey: key, limit: limit)
        if !cached.isEmpty { return cached }

        // 2) Otherwise, fetch remote URLs then download + compress + store
        guard let remoteURLs = try? await ThemeParksService.shared.pictureURLs(for: parkName, limit: limit), !remoteURLs.isEmpty else {
            return []
        }

        var stored: [URL] = []
        for (idx, remoteURL) in remoteURLs.enumerated() {
            do {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { continue }
                guard let image = UIImage(data: data) else { continue }

                let processed = await downscaleAndCompress(image: image)
                let fileURL = try store(data: processed, key: key, index: idx)
                stored.append(fileURL)
            } catch {
                // Skip this image on error
                continue
            }
        }

        return stored
    }

    // MARK: - Internal helpers
    /// Dossier `Application Support` dédié au cache d’images.
    private func appSupportDirectory() throws -> URL {
        let url = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url.appendingPathComponent(directoryName, isDirectory: true)
    }

    /// Crée le dossier de cache s’il n’existe pas.
    private func ensureDirectoryExists() throws {
        let dir = try appSupportDirectory()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// Construit l’URL locale d’une image pour une clé et un index donné.
    private func fileURL(forKey key: String, index: Int) throws -> URL {
        try appSupportDirectory().appendingPathComponent("\(key)-\(index).jpg")
    }

    /// Retourne les fichiers existants pour la clé (jusqu’à `limit`).
    private func existingLocalFiles(forKey key: String, limit: Int) -> [URL] {
        var urls: [URL] = []
        for i in 0..<limit {
            if let u = try? fileURL(forKey: key, index: i), fileManager.fileExists(atPath: u.path) {
                urls.append(u)
            }
        }
        return urls
    }

    /// Écrit les données sur disque de façon atomique et retourne l’URL.
    private func store(data: Data, key: String, index: Int) throws -> URL {
        let url = try fileURL(forKey: key, index: index)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Normalise un nom de parc en clé de fichier (a-z0-9 et tirets).
    private func makeKey(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let replaced = folded.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
        let trimmed = replaced.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let collapsed = trimmed.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        return collapsed.lowercased()
    }

    /// Redimensionne l’image en carré et compresse en JPEG.
    private func downscaleAndCompress(image: UIImage) async -> Data {
        // Render a square image (aspect-fill) into targetMaxDimension x targetMaxDimension
        let targetSide = targetMaxDimension
        let targetSize = CGSize(width: targetSide, height: targetSide)

        // Compute scale to ensure the entire square is covered (aspect fill)
        let imgSize = image.size
        let scale = max(targetSide / max(imgSize.width, 1), targetSide / max(imgSize.height, 1))
        let scaledSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
        let x = (targetSide - scaledSize.width) / 2
        let y = (targetSide - scaledSize.height) / 2
        let drawRect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let square = renderer.image { _ in
            UIColor.clear.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
            image.draw(in: drawRect)
        }
        return square.jpegData(compressionQuality: compressionQuality) ?? (image.jpegData(compressionQuality: compressionQuality) ?? Data())
    }
}
