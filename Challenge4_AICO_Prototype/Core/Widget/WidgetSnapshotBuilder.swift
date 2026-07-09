import Foundation

enum WidgetSnapshotBuilder {
    static func build(
        recipients: [RecipientProfile],
        records: [RecordEntry],
        preferredRecipientId: UUID? = nil
    ) -> AICOWidgetSnapshot {
        let sortedRecipients = recipients.sorted { $0.createdAt < $1.createdAt }
        let defaultRecipient = preferredRecipientId.flatMap { preferredId in
            sortedRecipients.first { $0.id == preferredId }
        } ?? sortedRecipients.first

        guard let defaultRecipient else {
            return .fallback
        }

        let calendar = Calendar.current
        let todayRecords = records.filter {
            $0.recipientId == defaultRecipient.id && calendar.isDateInToday($0.createdAt)
        }
        let mostFrequentBehavior = topBehavior(in: todayRecords)
        let recipientNames = Dictionary(uniqueKeysWithValues: recipients.map { ($0.id, $0.nickname) })

        let recentRecords = records
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { record in
                AICOWidgetRecordSummary(
                    createdAt: record.createdAt,
                    recipientName: recipientNames[record.recipientId] ?? "등록된 대상자",
                    behaviorSummary: record.behaviorCategories.first ?? "B단계 없음",
                    contextSummary: record.antecedentCategories.first
                )
            }

        return AICOWidgetSnapshot(
            defaultRecipientId: defaultRecipient.id.uuidString,
            defaultRecipientName: defaultRecipient.nickname,
            todayRecordCount: todayRecords.count,
            mostFrequentBehavior: mostFrequentBehavior,
            recentRecords: Array(recentRecords),
            updatedAt: Date()
        )
    }

    private static func topBehavior(in records: [RecordEntry]) -> String? {
        Dictionary(grouping: records.flatMap(\.behaviorCategories), by: { $0 })
            .map { (name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.name < $1.name
                }
                return $0.count > $1.count
            }
            .first?
            .name
    }
}
