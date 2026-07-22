import Foundation
import SwiftData

@Model
final class RecordEntry {
    @Attribute(.unique) var id: UUID
    var recipientId: UUID
    var createdAt: Date
    var recordDate: Date?
    var antecedentCategories: [String]
    var behaviorCategories: [String]
    var consequenceCategories: [String]
    var note: String?
    var attachmentNames: [String]

    init(
        id: UUID = UUID(),
        recipientId: UUID,
        createdAt: Date = Date(),
        recordDate: Date? = nil,
        antecedentCategories: [String] = [],
        behaviorCategories: [String] = [],
        consequenceCategories: [String] = [],
        note: String? = nil,
        attachmentNames: [String] = []
    ) {
        self.id = id
        self.recipientId = recipientId
        self.createdAt = createdAt
        self.recordDate = recordDate
        self.antecedentCategories = antecedentCategories
        self.behaviorCategories = behaviorCategories
        self.consequenceCategories = consequenceCategories
        self.note = note
        self.attachmentNames = attachmentNames
    }

    var effectiveRecordDate: Date {
        recordDate ?? createdAt
    }
}
