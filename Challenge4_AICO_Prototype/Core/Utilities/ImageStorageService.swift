import Foundation
import UIKit

enum ImageStorageService {
    private static let directoryName = "AICOImages"

    static func saveImageData(_ data: Data, prefix: String) throws -> String {
        let directory = try imageDirectory()
        let fileName = "\(prefix)-\(UUID().uuidString).jpg"
        let fileURL = directory.appendingPathComponent(fileName)

        if let image = UIImage(data: data), let jpegData = image.jpegData(compressionQuality: 0.82) {
            try jpegData.write(to: fileURL, options: .atomic)
        } else {
            try data.write(to: fileURL, options: .atomic)
        }

        return fileName
    }

    static func image(for fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        guard let directory = try? imageDirectory() else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(fileName).path)
    }

    static func deleteImage(named fileName: String?) {
        guard let fileName, let directory = try? imageDirectory() else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
    }

    private static func imageDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }
}
