import SwiftUI

struct ArchiveRecordCardView: View {
    let record: RecordEntry
    let recipientName: String

    private var title: String {
        record.behaviorCategories.first ?? recipientName
    }

    private var stageSummaries: [ArchiveCardStageSummary] {
        [
            ArchiveCardStageSummary(stage: "A", values: record.antecedentCategories),
            ArchiveCardStageSummary(stage: "B", values: record.behaviorCategories),
            ArchiveCardStageSummary(stage: "C", values: record.consequenceCategories)
        ]
        .filter { !$0.values.isEmpty }
        .prefix(2)
        .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.createdAt.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute()))
                    .font(.caption)
                    .foregroundStyle(AICOTheme.textGray)
                    .lineLimit(1)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(stageSummaries) { summary in
                    ArchiveStageChipRow(summary: summary)
                }
            }

            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(AICOTheme.darkGray)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 206, alignment: .topLeading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 6)
        .accessibilityElement(children: .combine)
    }
}

private struct ArchiveStageChipRow: View {
    let summary: ArchiveCardStageSummary

    var body: some View {
        HStack(spacing: 4) {
            Text(summary.stage)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AICOTheme.primaryOrange, in: Circle())

            Text(summary.values.first ?? "")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AICOTheme.primaryOrange)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(AICOTheme.primaryOrange.opacity(0.1), in: Capsule())
        }
    }
}

private struct ArchiveCardStageSummary: Identifiable {
    let stage: String
    let values: [String]

    var id: String { stage }
}
