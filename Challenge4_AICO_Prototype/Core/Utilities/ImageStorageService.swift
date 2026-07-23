import Foundation
import UniformTypeIdentifiers
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
        guard let fileURL = fileURL(for: fileName), !isVideo(fileURL.lastPathComponent) else {
            return nil
        }
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func saveMediaFile(
        at sourceURL: URL,
        prefix: String,
        fileExtension: String
    ) throws -> String {
        let directory = try imageDirectory()
        let safeExtension = sanitizedFileExtension(fileExtension)
        let fileName = "\(prefix)-\(UUID().uuidString).\(safeExtension)"
        let destinationURL = directory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return fileName
    }

    static func fileURL(for fileName: String?) -> URL? {
        guard let fileName,
              !fileName.isEmpty,
              fileName == URL(fileURLWithPath: fileName).lastPathComponent,
              let directory = try? imageDirectory()
        else {
            return nil
        }

        let fileURL = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return fileURL
    }

    static func isVideo(_ fileName: String) -> Bool {
        guard let type = UTType(filenameExtension: URL(fileURLWithPath: fileName).pathExtension) else {
            return false
        }
        return type.conforms(to: .movie)
    }

    static func deleteImage(named fileName: String?) {
        guard let fileURL = fileURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: fileURL)
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

    private static func sanitizedFileExtension(_ fileExtension: String) -> String {
        let sanitized = fileExtension
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
        return sanitized.isEmpty ? "mov" : String(sanitized.prefix(10))
    }
}
