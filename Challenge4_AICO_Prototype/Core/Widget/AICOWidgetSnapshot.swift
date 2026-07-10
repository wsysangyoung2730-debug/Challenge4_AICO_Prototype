import Foundation

struct AICOWidgetSnapshot: Codable {
    let defaultRecipientId: String?
    let defaultRecipientName: String
    let todayRecordCount: Int
    let mostFrequentBehavior: String?
    let recentRecords: [AICOWidgetRecordSummary]
    let updatedAt: Date

    static let fallback = AICOWidgetSnapshot(
        defaultRecipientId: nil,
        defaultRecipientName: "AICO",
        todayRecordCount: 0,
        mostFrequentBehavior: nil,
        recentRecords: [],
        updatedAt: Date()
    )
}
