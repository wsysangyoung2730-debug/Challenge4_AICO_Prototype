import Foundation
import SwiftData

enum RecordCategoryStage: String, CaseIterable, Codable, Hashable {
    case antecedent
    case behavior
    case consequence
}

@Model
final class RecordCategory {
    @Attribute(.unique) var id: UUID
    var stageRawValue: String
    var name: String
    var isCustom: Bool
    var createdAt: Date

    var stage: RecordCategoryStage {
        get {
            RecordCategoryStage(rawValue: stageRawValue) ?? .antecedent
        }
        set {
            stageRawValue = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        stage: RecordCategoryStage,
        name: String,
        isCustom: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.stageRawValue = stage.rawValue
        self.name = name
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}
