import SwiftUI

struct ArchiveRecordCardView: View {
    let record: RecordEntry
    let recipientName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipientName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AICOTheme.textGray)
                }

                Spacer()

                if !record.attachmentNames.isEmpty {
                    Label("첨부", systemImage: "paperclip")
                        .font(.caption)
                        .foregroundStyle(AICOTheme.primaryOrange)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                ArchiveStageSummaryRow(label: "[A단계]", values: record.antecedentCategories)
                ArchiveStageSummaryRow(label: "[B단계]", values: record.behaviorCategories)
                ArchiveStageSummaryRow(label: "[C단계]", values: record.consequenceCategories)
            }

            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(AICOTheme.textGray)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                .stroke(AICOTheme.primaryOrange.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }
}

struct ArchiveStageSummaryRow: View {
    let label: String
    let values: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 48, alignment: .leading)

            Text(summaryText)
                .font(.subheadline)
                .foregroundStyle(values.isEmpty ? AICOTheme.textGray : .primary)
                .lineLimit(2)

            Spacer()
        }
    }

    private var summaryText: String {
        let text = values.prefix(3).joined(separator: ", ")
        return text.isEmpty ? "선택 없음" : text
    }
}
