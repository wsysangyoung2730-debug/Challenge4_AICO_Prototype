import Foundation

enum SharedPhotoAttachmentStore {
    private static let directoryName = "SharedPhotoAttachments"
    private static let metadataKeyPrefix = "aico.shared.photo."

    static func saveImageData(_ data: Data, source: String = "share-extension") throws -> SharedPhotoAttachment {
        let id = UUID().uuidString
        let fileName = "shared-photo-\(id).jpg"
        let fileURL = try directoryURL().appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)

        let attachment = SharedPhotoAttachment(
            id: id,
            fileName: fileName,
            createdAt: Date(),
            source: source
        )
        saveMetadata(attachment)
        return attachment
    }

    static func attachment(id: String) -> SharedPhotoAttachment? {
        guard !id.isEmpty,
              let data = userDefaults.data(forKey: metadataKeyPrefix + id),
              let attachment = try? JSONDecoder().decode(SharedPhotoAttachment.self, from: data)
        else {
            return nil
        }

        return attachment
    }

    static func imageData(for attachmentId: String) -> Data? {
        guard let attachment = attachment(id: attachmentId),
              let fileURL = try? directoryURL().appendingPathComponent(attachment.fileName)
        else {
            return nil
        }

        return try? Data(contentsOf: fileURL)
    }

    static func deleteAttachment(id: String) {
        guard let attachment = attachment(id: id),
              let fileURL = try? directoryURL().appendingPathComponent(attachment.fileName)
        else {
            return
        }

        try? FileManager.default.removeItem(at: fileURL)
        userDefaults.removeObject(forKey: metadataKeyPrefix + id)
    }

    private static func saveMetadata(_ attachment: SharedPhotoAttachment) {
        guard let data = try? JSONEncoder().encode(attachment) else { return }
        userDefaults.set(data, forKey: metadataKeyPrefix + attachment.id)
    }

    private static var userDefaults: UserDefaults {
        UserDefaults(suiteName: AICOAppGroup.identifier) ?? .standard
    }

    private static func directoryURL() throws -> URL {
        let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AICOAppGroup.identifier)
            ?? FileManager.default.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }
}
