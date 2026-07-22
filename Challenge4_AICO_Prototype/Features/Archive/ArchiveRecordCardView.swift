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
            ArchiveCardStageSummary(stage: "C", values: record.consequenceCategories)
        ]
        .filter { !$0.values.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ArchiveRecordDateFormatter.string(from: record.effectiveRecordDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
                    .lineLimit(1)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(stageSummaries) { summary in
                    ArchiveStageChipRow(summary: summary)
                }
            }

            Text(displayNote)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.darkGray)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 223, alignment: .topLeading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 6)
        .accessibilityElement(children: .combine)
    }

    private var displayNote: String {
        guard let note = record.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty
        else {
            return "없음"
        }
        return note
    }
}

private struct ArchiveStageChipRow: View {
    let summary: ArchiveCardStageSummary

    var body: some View {
        HStack(spacing: 4) {
            Text(summary.stage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AICOTheme.primaryOrange, in: Circle())

            Text(summary.values.first ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AICOTheme.primaryOrange)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(AICOTheme.primaryOrange.opacity(0.1), in: Capsule())
        }
    }
}

private enum ArchiveRecordDateFormatter {
    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter
    }()
}

private struct ArchiveCardStageSummary: Identifiable {
    let stage: String
    let values: [String]

    var id: String { stage }
}
