import Foundation

struct ReportSummary: Hashable {
    var totalRecordCount: Int
    var notableChanges: [String]
    var antecedentTop3: [String]
    var behaviorTop3: [String]
    var consequenceTop3: [String]
}
