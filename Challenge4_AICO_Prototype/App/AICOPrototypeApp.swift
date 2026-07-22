import CloudKit
import SwiftData
import SwiftUI

@main
struct AICOPrototypeApp: App {
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

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        Task {
            await GuardianSyncManager.registerSubscriptionIfNeeded()
            await GuardianAutoSync.sync()
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        let container = CKContainer(identifier: GuardianSyncManager.containerID)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        operation.perShareResultBlock = { _, result in
            if case let .failure(error) = result { print("공유 수락 실패:", error) }
        }
        operation.acceptSharesResultBlock = { _ in
            
            Task {
                await GuardianSyncManager.registerSubscriptionIfNeeded()
                await GuardianAutoSync.sync()
            }
        }
        container.add(operation)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await GuardianAutoSync.sync()
            completionHandler(.newData)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("원격 알림 등록 실패:", error)
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            GuardianSyncStatus.shared.message = "공유 수락 처리 중…"
        }
        
        let container = CKContainer(identifier: GuardianSyncManager.containerID)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        operation.perShareResultBlock = { _, result in
            if case let .failure(error) = result {
                print("공유 수락 실패:", error)
            }
        }
        operation.acceptSharesResultBlock = { result in
            Task { @MainActor in
                if case .failure = result {
                    GuardianSyncStatus.shared.message = "초대 수락에 실패했어요. 링크를 다시 열어보세요."
                    return
                }
                GuardianSyncStatus.shared.isConnected = true
                GuardianSyncStatus.shared.message = "연결됐어요"
                await GuardianSyncManager.registerSubscriptionIfNeeded()
                await GuardianAutoSync.sync()
            }
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
    
    static func setupOwnerShare() async throws -> CKShare {
        let db = container.privateCloudDatabase
        let zone = CKRecordZone(zoneName: zoneName)
        let savedZone = try await db.save(zone)
        
        // 중복 생성 방지 + URL 있는 버전 사용
        let existingShareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: savedZone.zoneID)
        if let existing = try? await db.record(for: existingShareID) as? CKShare, existing.url != nil {
            return existing
        }
        
        let share = CKShare(recordZoneID: savedZone.zoneID)
        share[CKShare.SystemFieldKey.title] = "AICO 보호자 공유" as CKRecordValue
        share.publicPermission = .readWrite
        
        let result = try await db.modifyRecords(saving: [share], deleting: [])
        if case let .success(saved)? = result.saveResults[share.recordID],
           let savedShare = saved as? CKShare {
            return savedShare
        }
        return share
    }
    
    static func resolveTarget() async throws -> (db: CKDatabase, zoneID: CKRecordZone.ID)? {
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        if let zone = sharedZones.first(where: { $0.zoneID.zoneName == zoneName }) {
            return (container.sharedCloudDatabase, zone.zoneID)
        }
        let privateZones = try await container.privateCloudDatabase.allRecordZones()
        if let zone = privateZones.first(where: { $0.zoneID.zoneName == zoneName }) {
            return (container.privateCloudDatabase, zone.zoneID)
        }
        return nil
    }
    
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
    
    static func resetSharing() async throws {
        let privateZones = try await container.privateCloudDatabase.allRecordZones()
        if let zone = privateZones.first(where: { $0.zoneID.zoneName == zoneName }) {
            _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [], deleting: [zone.zoneID])
        }
    }
    
    static func registerSubscriptionIfNeeded() async {
        guard let target = try? await resolveTarget() else { return }
        let subscription = CKDatabaseSubscription(subscriptionID: "guardian-zone-changes")
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try? await target.db.modifySubscriptions(saving: [subscription], deleting: [])
    }
    
    /// 주어진 기록 id들 공유 존 삭제
    static func deleteRecords(ids: [UUID]) async {
        guard !ids.isEmpty, let target = try? await resolveTarget() else { return }
        let recordIDs = ids.map { CKRecord.ID(recordName: $0.uuidString, zoneID: target.zoneID) }
        _ = try? await target.db.modifyRecords(saving: [], deleting: recordIDs)
    }

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

// MARK: - 자동 동기화 서비스

// 보호자 공유 연결/동기화 상태
@MainActor
final class GuardianSyncStatus: ObservableObject {
    static let shared = GuardianSyncStatus()
    @Published var message: String = "연결 상태 확인 중…"
    @Published var isConnected: Bool = false
    private init() {}
}

@MainActor
enum GuardianAutoSync {
    private static var isRunning = false
    static func sync() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        
        let status = GuardianSyncStatus.shared
        
        let context = SwiftDataContainer.shared.mainContext
        let calendar = Calendar.current
        let localRecords = (try? context.fetch(FetchDescriptor<RecordEntry>())) ?? []
        var recipients = (try? context.fetch(FetchDescriptor<RecipientProfile>())) ?? []
        
        guard (try? await GuardianSyncManager.resolveTarget()) != nil else {
            status.isConnected = false
            status.message = "아직 연결되지 않았어요"
            return
        }
        status.isConnected = true
        
        do {
            
            let mine = localRecords.filter { !$0.isRemote && calendar.isDateInToday($0.createdAt) }
            let payload = mine.map { record in
                GuardianRecordData(
                    id: record.id,
                    recipientName: recipients.first { $0.id == record.recipientId }?.nickname ?? "보호자 공유",
                    createdAt: record.createdAt,
                    antecedent: record.antecedentCategories,
                    behavior: record.behaviorCategories,
                    consequence: record.consequenceCategories,
                    note: record.note
                )
            }
            try await GuardianSyncManager.push(payload)
            
            let remote = try await GuardianSyncManager.pullToday()
            var added = 0
            var updated = 0
            for data in remote {
                if let local = localRecords.first(where: { $0.id == data.id }) {
                    guard local.isRemote else { continue }
                    updated += 1
                    local.recipientId = recipientID(named: data.recipientName, in: &recipients, context: context)
                    local.createdAt = data.createdAt
                    local.antecedentCategories = data.antecedent
                    local.behaviorCategories = data.behavior
                    local.consequenceCategories = data.consequence
                    local.note = data.note
                } else {
                    let entry = RecordEntry(
                        id: data.id,
                        recipientId: recipientID(named: data.recipientName, in: &recipients, context: context),
                        createdAt: data.createdAt,
                        antecedentCategories: data.antecedent,
                        behaviorCategories: data.behavior,
                        consequenceCategories: data.consequence,
                        note: data.note
                    )
                    entry.isRemote = true
                    context.insert(entry)
                    added += 1
                }
            }
            try? context.save()
            status.message = "연결됨 · 방금 동기화했어요"
            _ = (added, updated)
        } catch {
            print("자동 동기화 실패:", error)
            status.message = "동기화에 실패했어요. 잠시 후 다시 시도돼요."
        }
    }
    /// 내가 직접 쓴 기록은 삭제X
    static func disconnectAndReset() async {
        let status = GuardianSyncStatus.shared
        status.message = "연결을 끊는 중…"
        
        try? await GuardianSyncManager.resetSharing()
        let context = SwiftDataContainer.shared.mainContext
        let received = ((try? context.fetch(FetchDescriptor<RecordEntry>())) ?? []).filter(\.isRemote)
        received.forEach(context.delete)
        try? context.save()
        
        status.isConnected = false
        status.message = "연결이 해제됐어요"
    }
    
    private static func recipientID(
        named name: String,
        in recipients: inout [RecipientProfile],
        context: ModelContext
    ) -> UUID {
        if let existing = recipients.first(where: { $0.nickname == name }) {
            return existing.id
        }
        let profile = RecipientProfile(nickname: name)
        context.insert(profile)
        recipients.append(profile)
        return profile.id
    }
}
