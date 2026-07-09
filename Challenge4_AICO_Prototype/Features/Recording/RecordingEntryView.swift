import SwiftData
import SwiftUI

struct RecordingEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    var body: some View {
        Group {
            if let activeRecipient = recipients.first {
                ZStack {
                    ABCRecordingFlowView(
                        recipients: recipients,
                        initialRecipient: activeRecipient
                    )

                    if !sessionState.hasSeenRecordingTutorial {
                        RecordingTutorialOverlayView {
                            sessionState.completeRecordingTutorial()
                        }
                    }
                }
            } else {
                RecipientRegistrationView()
            }
        }
        .navigationTitle("기록하기")
        .background(AICOTheme.softBackground)
        .onAppear {
            seedDefaultCategoriesIfNeeded()
        }
    }

    private func seedDefaultCategoriesIfNeeded() {
        var existingKeys = Set(categories.map { "\($0.stageRawValue)|\($0.name)" })

        for seed in DefaultRecordCategorySeed.all {
            let key = "\(seed.stage.rawValue)|\(seed.name)"
            guard !existingKeys.contains(key) else { continue }

            modelContext.insert(
                RecordCategory(
                    stage: seed.stage,
                    name: seed.name,
                    isCustom: false
                )
            )
            existingKeys.insert(key)
        }

        try? modelContext.save()
    }
}

#Preview {
    RecordingEntryView()
}

private enum DefaultRecordCategorySeed {
    static let all: [(stage: RecordCategoryStage, name: String)] = [
        (.antecedent, "식사 중"),
        (.antecedent, "이동 중"),
        (.antecedent, "등원/하원"),
        (.antecedent, "사람이 많음"),
        (.antecedent, "소음이 큼"),
        (.antecedent, "일정 변경"),
        (.antecedent, "원하는 것 거절"),
        (.antecedent, "전환 상황"),
        (.antecedent, "낯선 장소"),
        (.antecedent, "대기 상황"),
        (.behavior, "울음"),
        (.behavior, "소리 지름"),
        (.behavior, "반복 행동"),
        (.behavior, "바닥에 누움"),
        (.behavior, "귀를 막음"),
        (.behavior, "식사 거부"),
        (.behavior, "약 복용 거부"),
        (.behavior, "도망가려 함"),
        (.behavior, "특정 물건 집착"),
        (.behavior, "요구 파악 어려움"),
        (.consequence, "기다려줌"),
        (.consequence, "조용한 공간 이동"),
        (.consequence, "좋아하는 물건 제공"),
        (.consequence, "시각자료 제시"),
        (.consequence, "물/간식 제공"),
        (.consequence, "약 복용 시도"),
        (.consequence, "안정됨"),
        (.consequence, "조금 나아짐"),
        (.consequence, "변화 없음"),
        (.consequence, "더 심해짐"),
        (.consequence, "추가 관찰 필요")
    ]
}
