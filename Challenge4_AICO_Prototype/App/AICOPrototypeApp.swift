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

    var body: some View {
        if sessionState.hasSeenServiceIntro {
            MainTabView()
        } else {
            ServiceIntroView {
                sessionState.completeServiceIntro()
            }
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            RecordingEntryView()
                .tabItem {
                    Label("기록", systemImage: "square.and.pencil")
                }

            ArchiveView()
                .tabItem {
                    Label("아카이브", systemImage: "archivebox.fill")
                }

            ReportView()
                .tabItem {
                    Label("리포트", systemImage: "chart.bar.xaxis")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
        .tint(AICOTheme.primaryOrange)
    }
}
