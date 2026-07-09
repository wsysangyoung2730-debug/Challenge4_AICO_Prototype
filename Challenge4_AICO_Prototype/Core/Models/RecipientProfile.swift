import Foundation

struct RecipientProfile: Identifiable, Hashable {
    let id: UUID
    var nickname: String
    var age: Int?
    var gender: String?
    var autismTraits: String?
    var profileImageName: String?

    init(
        id: UUID = UUID(),
        nickname: String,
        age: Int? = nil,
        gender: String? = nil,
        autismTraits: String? = nil,
        profileImageName: String? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.age = age
        self.gender = gender
        self.autismTraits = autismTraits
        self.profileImageName = profileImageName
    }
}
