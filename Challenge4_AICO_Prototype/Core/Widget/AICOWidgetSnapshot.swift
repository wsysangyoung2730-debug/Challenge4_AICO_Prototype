import Foundation

enum AICOAppGroup {
    // App Group capability must be enabled manually for both app and widget targets.
    static let identifier = "group.com.wsysangyoung2730.aico"
}

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
