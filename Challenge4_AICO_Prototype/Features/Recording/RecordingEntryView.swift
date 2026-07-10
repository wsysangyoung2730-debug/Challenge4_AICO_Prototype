import SwiftData
import SwiftUI

struct RecordingEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]

    let preferredRecipientID: UUID?
    let prefilledAttachmentID: String?

    init(preferredRecipientID: UUID? = nil, prefilledAttachmentID: String? = nil) {
        self.preferredRecipientID = preferredRecipientID
        self.prefilledAttachmentID = prefilledAttachmentID
    }

    var body: some View {
        Group {
            if let activeRecipient {
                ZStack {
                    ABCRecordingFlowView(
                        recipients: recipients,
                        initialRecipient: activeRecipient,
                        prefilledAttachmentID: prefilledAttachmentID
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
        .background(AICOTheme.softBackground)
        .onAppear {
            seedDefaultCategoriesIfNeeded()
            updateWidgetSnapshot()
        }
    }

    private var activeRecipient: RecipientProfile? {
        if let preferredRecipientID,
           let preferredRecipient = recipients.first(where: { $0.id == preferredRecipientID }) {
            return preferredRecipient
        }

        return recipients.first
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

    private func updateWidgetSnapshot() {
        let snapshot = WidgetSnapshotBuilder.build(
            recipients: recipients,
            records: records,
            preferredRecipientId: preferredRecipientID
        )
        WidgetSnapshotStore.save(snapshot)
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
