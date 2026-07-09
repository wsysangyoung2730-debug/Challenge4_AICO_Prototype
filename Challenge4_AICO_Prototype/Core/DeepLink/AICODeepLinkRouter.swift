import Foundation

enum AICODeepLinkRouter {
    static func parse(_ url: URL) -> AICODeepLink? {
        guard url.scheme == "aico" else { return nil }

        switch url.host {
        case "quick-record":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let recipientIdString = components?
                .queryItems?
                .first { $0.name == "recipientId" }?
                .value
            let recipientId = recipientIdString.flatMap(UUID.init(uuidString:))
            return .quickRecord(recipientId: recipientId)
        case "select-recipient-for-record":
            return .selectRecipientForRecord
        default:
            return nil
        }
    }
}
