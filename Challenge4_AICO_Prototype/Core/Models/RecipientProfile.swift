import Foundation
import SwiftData

@Model
final class RecipientProfile {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var age: Int?
    var gender: String?
    var autismTraits: String?
    var profileImageName: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        nickname: String,
        age: Int? = nil,
        gender: String? = nil,
        autismTraits: String? = nil,
        profileImageName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.age = age
        self.gender = gender
        self.autismTraits = autismTraits
        self.profileImageName = profileImageName
        self.createdAt = createdAt
    }
}
