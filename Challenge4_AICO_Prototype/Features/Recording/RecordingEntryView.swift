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

