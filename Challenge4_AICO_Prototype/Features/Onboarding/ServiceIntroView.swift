import SwiftUI

struct ServiceIntroView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            Spacer()

            Text(AppConstants.appName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AICOTheme.primaryOrange)

            Text("보호자가 상황, 행동, 대응을 차분히 기록하고 돌아볼 수 있도록 돕는 프로토타입입니다.")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 14) {
                IntroRow(
                    systemImage: "list.clipboard.fill",
                    text: "AICO는 맥락, 행동, 대응 결과를 ABC 구조로 기록하도록 돕습니다."
                )
                IntroRow(
                    systemImage: "person.fill.questionmark",
                    text: "처음에는 익명으로 시작해 민감한 정보를 입력하기 전에 앱 흐름을 먼저 이해할 수 있습니다."
                )
                IntroRow(
                    systemImage: "person.crop.circle.badge.plus",
                    text: "실제 기록 기능을 사용할 때 대상자 등록이 필요하도록 설계할 예정입니다."
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

            Spacer()
        }
        .padding(AICOTheme.screenPadding)
        .background(AICOTheme.softBackground)
    }
}

private struct IntroRow: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 24)

            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ServiceIntroView {}
}
