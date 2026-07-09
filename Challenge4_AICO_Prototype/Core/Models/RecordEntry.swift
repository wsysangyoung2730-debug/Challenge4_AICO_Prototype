import Foundation

struct RecordEntry: Identifiable, Hashable {
    let id: UUID
    var recipientId: UUID
    var createdAt: Date
    var antecedentCategories: [RecordCategory]
    var behaviorCategories: [RecordCategory]
    var consequenceCategories: [RecordCategory]
    var note: String?
    var attachmentNames: [String]

    init(
        id: UUID = UUID(),
        recipientId: UUID,
        createdAt: Date = Date(),
        antecedentCategories: [RecordCategory] = [],
        behaviorCategories: [RecordCategory] = [],
        consequenceCategories: [RecordCategory] = [],
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
