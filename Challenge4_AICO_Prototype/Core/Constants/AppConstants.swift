import Foundation

enum AppConstants {
    static let appName = "AICO"
    static let prototypeName = "Challenge4_AICO_Prototype"
}

enum DefaultRecordCategorySeed {
    static let all: [(stage: RecordCategoryStage, name: String)] = [
        (.antecedent, "배고픔"),
        (.antecedent, "피곤함"),
        (.antecedent, "통증/불편"),
        (.antecedent, "화장실"),
        (.antecedent, "소음"),
        (.antecedent, "냄새"),
        (.antecedent, "사람 많음"),
        (.antecedent, "장소 이동"),
        (.antecedent, "활동 전환"),
        (.antecedent, "요구 거절"),
        (.antecedent, "지시"),
        (.antecedent, "낯선 사람 접촉"),
        (.behavior, "공격 행동"),
        (.behavior, "회피/이탈"),
        (.behavior, "반복/집착 행동"),
        (.behavior, "자해 행동"),
        (.behavior, "감정 표현"),
        (.behavior, "의사표현 행동"),
        (.consequence, "음식/음료 제공"),
        (.consequence, "휴식 제공"),
        (.consequence, "공간 이동"),
        (.consequence, "안아줌"),
        (.consequence, "거리둠"),
        (.consequence, "그림/시각자료"),
        (.consequence, "활동 전환"),
        (.consequence, "진정됨"),
        (.consequence, "심해짐"),
        (.consequence, "반복됨"),
        (.consequence, "잠시 멈춤"),
        (.consequence, "행동 전환"),
        (.consequence, "변화없음")
    ]
}
