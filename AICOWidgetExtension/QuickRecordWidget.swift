import WidgetKit
import SwiftUI

struct QuickRecordWidget: Widget {
    let kind = "QuickRecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AICOWidgetProvider()) { entry in
            AICOWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AICO Quick Record")
        .description("오늘 기록 수와 빠른 기록 진입점을 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
