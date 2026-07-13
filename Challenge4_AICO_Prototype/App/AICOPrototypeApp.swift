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
                            .foregroundStyle(selectedTab == tab ? AICOTheme.primaryOrange : Color.black.opacity(0.82))
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
                    .foregroundStyle(Color.black.opacity(0.82))
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
