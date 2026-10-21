import Foundation
import UIKit
import CryptoKit
/// Image cache for artwork
class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("ImageCache")

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Get Image

    func image(for url: String) async -> UIImage? {
        let key = url as NSString

        // Check memory cache
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }

        // Check disk cache
        if let diskImage = loadImageFromDisk(for: url) {
            memoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }

        // Fetch from network
        guard let imageURL = URL(string: url) else { return nil }

        do {
            let data = try await URLSession.shared.data(from: imageURL).0
            if let image = UIImage(data: data) {
                // Save to caches
                memoryCache.setObject(image, forKey: key)
                saveImageToDisk(image, for: url)
                return image
            }
        } catch {
            print("Failed to fetch image: \(error)")
        }

        return nil
    }

    // MARK: - Disk Cache

    private func loadImageFromDisk(for url: String) -> UIImage? {
        let filename = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        return UIImage(contentsOfFile: fileURL.path)
    }

    private func saveImageToDisk(_ image: UIImage, for url: String) {
        let filename = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        try? data.write(to: fileURL)
    }

    // MARK: - Cache Management

    private func cacheKey(for url: String) -> String {
        return url.md5Hash()
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }

    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }
}

extension String {
    func md5Hash() -> String {
        let data = self.data(using: .utf8)!
        let hash = Insecure.MD5.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
