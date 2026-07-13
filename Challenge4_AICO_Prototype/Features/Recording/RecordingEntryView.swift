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
        let seedKeys = Set(DefaultRecordCategorySeed.all.map { "\($0.stage.rawValue)|\($0.name)" })

        for category in categories where !category.isCustom && !seedKeys.contains("\(category.stageRawValue)|\(category.name)") {
            modelContext.delete(category)
        }

        var existingKeys = Set(
            categories
                .filter { $0.isCustom || seedKeys.contains("\($0.stageRawValue)|\($0.name)") }
                .map { "\($0.stageRawValue)|\($0.name)" }
        )

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
        (.antecedent, "낯선 사람"),
        (.behavior, "공격 행동"),
        (.behavior, "회피/이탈"),
        (.behavior, "반복/집착"),
        (.behavior, "자해 행동"),
        (.behavior, "감정 표현"),
        (.behavior, "의사표현"),
        (.consequence, "음식/음료"),
        (.consequence, "휴식"),
        (.consequence, "공간 이동"),
        (.consequence, "안아줌"),
        (.consequence, "거리두기"),
        (.consequence, "시각자료"),
        (.consequence, "활동 전환"),
        (.consequence, "진정됨"),
        (.consequence, "심해짐"),
        (.consequence, "반복됨"),
        (.consequence, "잠시 멈춤"),
        (.consequence, "행동 전환"),
        (.consequence, "변화없음")
    ]
}
