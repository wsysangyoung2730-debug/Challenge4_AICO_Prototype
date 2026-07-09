import Foundation

enum RecordCategoryStage: String, CaseIterable, Hashable {
    case antecedent
    case behavior
    case consequence
}

struct RecordCategory: Identifiable, Hashable {
    let id: UUID
    var stage: RecordCategoryStage
    var name: String
    var isCustom: Bool

    init(
        id: UUID = UUID(),
        stage: RecordCategoryStage,
        name: String,
        isCustom: Bool = false
    ) {
        self.id = id
        self.stage = stage
        self.name = name
        self.isCustom = isCustom
    }
}
