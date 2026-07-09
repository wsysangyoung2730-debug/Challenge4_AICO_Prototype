import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotStore {
    private static let snapshotKey = "aico.widget.snapshot"

    static func save(_ snapshot: AICOWidgetSnapshot, reloadTimelines: Bool = true) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: snapshotKey)

        #if canImport(WidgetKit)
        if reloadTimelines {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }

    static func load() -> AICOWidgetSnapshot {
        guard let data = userDefaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(AICOWidgetSnapshot.self, from: data)
        else {
            return .fallback
        }

        return snapshot
    }

    private static var userDefaults: UserDefaults {
        UserDefaults(suiteName: AICOAppGroup.identifier) ?? .standard
    }
}
