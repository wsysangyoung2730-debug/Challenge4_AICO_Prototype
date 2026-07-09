import Foundation

enum AICODeepLink: Equatable, Identifiable {
    case quickRecord(recipientId: UUID?)
    case selectRecipientForRecord

    var id: String {
        switch self {
        case let .quickRecord(recipientId):
            "quick-record-\(recipientId?.uuidString ?? "default")"
        case .selectRecipientForRecord:
            "select-recipient-for-record"
        }
    }
}
