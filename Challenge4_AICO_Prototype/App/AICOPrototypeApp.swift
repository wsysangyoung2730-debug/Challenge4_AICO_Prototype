import CloudKit
import SwiftData
import SwiftUI

@main
struct AICOPrototypeApp: App {
    // CKShare 공유 수락(상대가 링크 누를 때) 처리에 필요
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sessionState = AnonymousSessionState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionState)
        }
        .modelContainer(SwiftDataContainer.shared)
    }
}

// 상대 보호자가 받은 공유 링크를 누르면 iOS가 여기로 초대 정보를 넘겨줌 → 수락
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        let container = CKContainer(identifier: GuardianSyncManager.containerID)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        operation.perShareResultBlock = { _, result in
            if case let .failure(error) = result { print("공유 수락 실패:", error) }
        }
        container.add(operation)
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

// MARK: - 보호자 간 공유/수동 동기화 (CKShare · 커스텀 존 공유)
// 커스텀 존 하나를 통째로 CKShare로 공유 → 두 보호자가 같이 읽고 씀.
// owner는 privateCloudDatabase, participant는 sharedCloudDatabase로 접근.
// CKRecord <-> RecordEntry 사이 다리
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
    static let zoneName = "GuardianSharedZone"
    static let recordType = "GuardianRecord"

    static var container: CKContainer { CKContainer(identifier: containerID) }

    // owner: 공유 존을 만들고 그 존 전체에 대한 CKShare 생성 (한 번만)
    static func setupOwnerShare() async throws -> CKShare {
        let zone = CKRecordZone(zoneName: zoneName)
        let savedZone = try await container.privateCloudDatabase.save(zone)
        let share = CKShare(recordZoneID: savedZone.zoneID)
        share[CKShare.SystemFieldKey.title] = "AICO 보호자 공유" as CKRecordValue
        share.publicPermission = .none
        _ = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
        return share
    }

    // 내가 owner인지 participant인지 판별 + 알맞은 DB/존. 미설정이면 nil.
    static func resolveTarget() async throws -> (db: CKDatabase, zoneID: CKRecordZone.ID)? {
        let privateZones = try await container.privateCloudDatabase.allRecordZones()
        if let zone = privateZones.first(where: { $0.zoneID.zoneName == zoneName }) {
            return (container.privateCloudDatabase, zone.zoneID)
        }
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        if let zone = sharedZones.first(where: { $0.zoneID.zoneName == zoneName }) {
            return (container.sharedCloudDatabase, zone.zoneID)
        }
        return nil
    }

    // 내 오늘 기록을 공유 존에 업로드 (.allKeys: 이미 있으면 덮어씀 → 수정분 반영)
    static func push(_ records: [GuardianRecordData]) async throws {
        guard let target = try await resolveTarget() else {
            throw NSError(domain: "GuardianSync", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "먼저 보호자 공유를 설정하거나 초대 링크를 수락하세요."])
        }
        guard !records.isEmpty else { return }
        let toSave = records.map { data -> CKRecord in
            let recordID = CKRecord.ID(recordName: data.id.uuidString, zoneID: target.zoneID)
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record["recipientName"] = data.recipientName as CKRecordValue
            record["createdAt"] = data.createdAt as CKRecordValue
            record["antecedent"] = data.antecedent as CKRecordValue
            record["behavior"] = data.behavior as CKRecordValue
            record["consequence"] = data.consequence as CKRecordValue
            if let note = data.note { record["note"] = note as CKRecordValue }
            return record
        }
        _ = try await target.db.modifyRecords(saving: toSave, deleting: [], savePolicy: .allKeys)
    }

    // 공유 존에서 '오늘' 기록을 모두 읽어옴 (내 것 + 상대 것)
    static func pullToday() async throws -> [GuardianRecordData] {
        guard let target = try await resolveTarget() else { return [] }
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await target.db.records(matching: query, inZoneWith: target.zoneID)

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
