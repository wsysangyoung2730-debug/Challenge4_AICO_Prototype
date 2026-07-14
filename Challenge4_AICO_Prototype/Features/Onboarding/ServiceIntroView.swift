import SwiftUI

struct ServiceIntroView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                Text(AppConstants.appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AICOTheme.primaryOrange)

                Text("아이의 순간을 더 잘 이해하기 위해")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("AICO는 보호자가 대상자의 상황, 행동, 대응을 가볍게 나누어 기록하고 다시 돌아볼 수 있도록 돕습니다.")
                    .font(.body)
                    .foregroundStyle(AICOTheme.textGray)

                VStack(spacing: 12) {
                    IntroCard(
                        title: "상황, 행동, 대응을 나누어 기록해요",
                        text: "A/B/C 구조로 중요한 순간을 차분히 정리할 수 있어요.",
                        systemImage: "list.clipboard.fill"
                    )
                    IntroCard(
                        title: "처음에는 익명으로 둘러봐요",
                        text: "민감한 대상자 정보는 바로 필요하지 않아요. 앱 흐름을 먼저 확인할 수 있어요.",
                        systemImage: "person.fill.questionmark"
                    )
                    IntroCard(
                        title: "쌓인 기록은 다시 확인해요",
                        text: "기록은 이후 아카이브와 리포트에서 패턴을 살펴보는 데 활용될 예정이에요.",
                        systemImage: "chart.bar.doc.horizontal"
                    )
                    IntroCard(
                        title: "실제 기록 전 대상자 등록을 요청해요",
                        text: "대상자 등록은 다음 단계의 기록 기능에서 필요한 시점에 안내합니다.",
                        systemImage: "person.crop.circle.badge.plus"
                    )
                }

                Button(action: onStart) {
                    Text("시작하기")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AICOTheme.primaryOrange)
                .padding(.top, 8)
            }
            .padding(AICOTheme.screenPadding)
        }
        .background(AICOTheme.softBackground)
    }
}

private struct IntroCard: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AICOTheme.textGray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }
}

#Preview {
    ServiceIntroView {}
}
