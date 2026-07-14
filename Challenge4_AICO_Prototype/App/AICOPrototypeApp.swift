import CloudKit
import SwiftData
import SwiftUI

@main
struct AICOPrototypeApp: App {
    @StateObject private var sessionState = AnonymousSessionState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionState)
        }
        .modelContainer(SwiftDataContainer.shared)
    }
}

private struct RootView: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @State private var pendingDeepLink: AICODeepLink?

    var body: some View {
        Group {
            if sessionState.hasSeenServiceIntro {
                MainTabView(pendingDeepLink: $pendingDeepLink)
            } else {
                ServiceIntroView {
                    sessionState.completeServiceIntro()
                }
            }
        }
        .onOpenURL { url in
            guard let deepLink = AICODeepLinkRouter.parse(url) else { return }
            if !sessionState.hasSeenServiceIntro {
                sessionState.completeServiceIntro()
            }
            pendingDeepLink = deepLink
        }
    }
}

private struct MainTabView: View {
    @Binding var pendingDeepLink: AICODeepLink?
    @State private var selectedTab: MainNavigationTab = .home
    @State private var activeDeepLink: AICODeepLink?
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                selectedView
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 104)
                    }

                FloatingBottomNavigationBar(selectedTab: $selectedTab)
            }
            .navigationDestination(item: $activeDeepLink) { deepLink in
                switch deepLink {
                case let .quickRecord(recipientId):
                    RecordingEntryView(preferredRecipientID: recipientId)
                case .selectRecipientForRecord:
                    QuickRecordRecipientPickerView()
                case let .recordFromPhoto(attachmentId):
                    RecordingEntryView(prefilledAttachmentID: attachmentId)
                }
            }
        }
        .onAppear {
            updateWidgetSnapshot()
            consumePendingDeepLink()
        }
        .onChange(of: pendingDeepLink) {
            consumePendingDeepLink()
        }
    }

    @ViewBuilder
    private var selectedView: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .archive:
            ArchiveView()
        case .report:
            ReportView()
        }
    }

    private func updateWidgetSnapshot() {
        let snapshot = WidgetSnapshotBuilder.build(recipients: recipients, records: records)
        WidgetSnapshotStore.save(snapshot)
    }

    private func consumePendingDeepLink() {
        guard let pendingDeepLink else { return }
        activeDeepLink = pendingDeepLink
        self.pendingDeepLink = nil
    }
}

private struct FloatingBottomNavigationBar: View {
    @Binding var selectedTab: MainNavigationTab

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(MainNavigationTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selectedTab == tab ? AICOTheme.primaryOrange : AICOTheme.darkGray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay {
                                            Capsule()
                                                .fill(Color.white.opacity(0.36))
                                        }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)

            NavigationLink {
                RecordingEntryView()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AICOTheme.darkGray)
                    .frame(width: 48, height: 48)
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("기록 시작")
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 16)
    }
}

private enum MainNavigationTab: CaseIterable, Identifiable {
    case home
    case archive
    case report

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            "홈"
        case .archive:
            "아카이브"
        case .report:
            "리포트"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house.fill"
        case .archive:
            "archivebox.fill"
        case .report:
            "chart.pie.fill"
        }
    }
}

// MARK: - 보호자 간 코드 기반 수동 동기화 (Public DB)
// CKRecord <->RecordEntry
struct GuardianRecordData {
    let id: UUID
    let recipientName: String
    let createdAt: Date
    let antecedent: [String]
    let behavior: [String]
    let consequence: [String]
    let note: String?
}

enum GuardianSyncManager {
    // 팀 CloudKit 컨테이너 ID로 교체 + iCloud/CloudKit capability 추가
    static let containerID = "iCloud.com.gonn.aico.test"
    static let recordType = "SharedRecord"

    static var db: CKDatabase { CKContainer(identifier: containerID).publicCloudDatabase }
    
    static func makeRoomCode() -> String {
        String(format: "%06d", Int.random(in: 0...999_999))
    }
    
    static func push(_ records: [GuardianRecordData], roomCode: String) async throws {
        guard !roomCode.isEmpty else {
            throw NSError(domain: "GuardianSync", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "설정에서 공유방을 먼저 만들거나 참여하세요."])
        }
        guard !records.isEmpty else { return }
        let toSave = records.map { data -> CKRecord in
            let recordID = CKRecord.ID(recordName: data.id.uuidString)
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record["roomCode"] = roomCode as CKRecordValue
            record["recipientName"] = data.recipientName as CKRecordValue
            record["createdAt"] = data.createdAt as CKRecordValue
            record["antecedent"] = data.antecedent as CKRecordValue
            record["behavior"] = data.behavior as CKRecordValue
            record["consequence"] = data.consequence as CKRecordValue
            if let note = data.note { record["note"] = note as CKRecordValue }
            return record
        }
        _ = try await db.modifyRecords(saving: toSave, deleting: [], savePolicy: .allKeys)
    }

    static func pullToday(roomCode: String) async throws -> [GuardianRecordData] {
        guard !roomCode.isEmpty else { return [] }
        let predicate = NSPredicate(format: "roomCode == %@", roomCode)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let result = try await db.records(matching: query)

        let calendar = Calendar.current
        var out: [GuardianRecordData] = []
        for (_, recordResult) in result.matchResults {
            guard let record = try? recordResult.get() else { continue }
            guard let created = record["createdAt"] as? Date, calendar.isDateInToday(created) else { continue }
            guard let id = UUID(uuidString: record.recordID.recordName) else { continue }
            out.append(
                GuardianRecordData(
                    id: id,
                    recipientName: record["recipientName"] as? String ?? "보호자 공유",
                    createdAt: created,
                    antecedent: record["antecedent"] as? [String] ?? [],
                    behavior: record["behavior"] as? [String] ?? [],
                    consequence: record["consequence"] as? [String] ?? [],
                    note: record["note"] as? String
                )
            )
        }
        return out
    }
}
