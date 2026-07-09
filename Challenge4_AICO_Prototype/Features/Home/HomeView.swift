import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppConstants.appName)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("상황, 행동, 대응을 따뜻하게 기록하는 보호자 지원 앱")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    PlaceholderCardView(
                        title: "최근 기록",
                        message: "대상자 등록 후 저장한 ABC 기록이 이곳에 표시됩니다.",
                        systemImage: "clock.fill"
                    )

                    PlaceholderCardView(
                        title: "간단 리포트",
                        message: "이번 주 기록 수와 주요 변화 요약이 표시될 예정입니다.",
                        systemImage: "chart.bar.fill"
                    )

                    PlaceholderCardView(
                        title: "정보 피드",
                        message: "보호자에게 도움이 되는 안내와 콘텐츠가 표시될 예정입니다.",
                        systemImage: "text.bubble.fill"
                    )
                }
                .padding(AICOTheme.screenPadding)
            }
            .navigationTitle(AppConstants.appName)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "bell")
                    }
                    .accessibilityLabel("알림")

                    Button {
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("프로필 및 설정")
                }
            }
            .background(AICOTheme.softBackground)
        }
    }
}

#Preview {
    HomeView()
}
