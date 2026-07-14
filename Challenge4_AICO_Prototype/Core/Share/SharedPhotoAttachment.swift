import Foundation

struct SharedPhotoAttachment: Codable, Equatable, Identifiable {
    let id: String
    let fileName: String
    let createdAt: Date
    let source: String
}
