import SwiftData

enum SwiftDataContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            CaregiverProfile.self,
            RecipientProfile.self,
            RecordEntry.self,
            RecordCategory.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }()
}
