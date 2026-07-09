import Foundation

struct AICOWidgetRecordSummary: Codable, Identifiable {
    var id: String {
        "\(createdAt.timeIntervalSince1970)-\(recipientName)-\(behaviorSummary)"
    }

    let createdAt: Date
    let recipientName: String
    let behaviorSummary: String
    let contextSummary: String?
}
