import Foundation

struct ReportSummary: Hashable {
    var totalRecordCount: Int
    var notableChanges: [String]
    var antecedentTop3: [RecordCategory]
    var behaviorTop3: [RecordCategory]
    var consequenceTop3: [RecordCategory]
}
