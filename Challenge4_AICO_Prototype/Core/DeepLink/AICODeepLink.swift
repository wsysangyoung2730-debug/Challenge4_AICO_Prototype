import Foundation

enum AICODeepLink: Equatable, Identifiable, Hashable {
    case quickRecord(recipientId: UUID?)
    case selectRecipientForRecord
    case recordFromPhoto(attachmentId: String)

    var id: String {
        switch self {
        case let .quickRecord(recipientId):
            "quick-record-\(recipientId?.uuidString ?? "default")"
        case .selectRecipientForRecord:
            "select-recipient-for-record"
        case let .recordFromPhoto(attachmentId):
            "record-from-photo-\(attachmentId)"
        }
    }
}
