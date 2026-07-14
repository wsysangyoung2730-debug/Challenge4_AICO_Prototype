import Foundation
import SwiftData

@Model
final class RecordEntry {
    @Attribute(.unique) var id: UUID
    var recipientId: UUID
    var createdAt: Date
    var antecedentCategories: [String]
    var behaviorCategories: [String]
    var consequenceCategories: [String]
    var note: String?
    var attachmentNames: [String]

    // 보호자 간 수동 동기화용
    var isRemote: Bool = false

    init(
        id: UUID = UUID(),
        recipientId: UUID,
        createdAt: Date = Date(),
        antecedentCategories: [String] = [],
        behaviorCategories: [String] = [],
        consequenceCategories: [String] = [],
        note: String? = nil,
        attachmentNames: [String] = []
    ) {
        self.id = id
        self.recipientId = recipientId
        self.createdAt = createdAt
        self.antecedentCategories = antecedentCategories
        self.behaviorCategories = behaviorCategories
        self.consequenceCategories = consequenceCategories
        self.note = note
        self.attachmentNames = attachmentNames
    }
}
