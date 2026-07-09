import WidgetKit

struct AICOWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: AICOWidgetSnapshot
}

struct AICOWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AICOWidgetEntry {
        AICOWidgetEntry(date: Date(), snapshot: .fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (AICOWidgetEntry) -> Void) {
        completion(AICOWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AICOWidgetEntry>) -> Void) {
        let entry = AICOWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}
