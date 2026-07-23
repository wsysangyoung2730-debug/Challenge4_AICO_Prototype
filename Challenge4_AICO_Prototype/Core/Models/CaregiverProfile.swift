import Foundation
import SwiftData

@Model
final class CaregiverProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var relationship: String
    var profileImageName: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        relationship: String,
        profileImageName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.profileImageName = profileImageName
        self.createdAt = createdAt
    }
}
