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
            VStack(spacing: 0) {
                selectedView

                Divider()

                HStack(spacing: 16) {
                    ForEach(MainNavigationTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.systemImage)
                                    .font(.title3)

                                Text(tab.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(selectedTab == tab ? AICOTheme.primaryOrange : .secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        RecordingEntryView()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .fontWeight(.bold)

                            Text("기록")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(AICOTheme.primaryOrange)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("기록 시작")
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(.regularMaterial)
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
            "chart.bar.xaxis"
        }
    }
}
