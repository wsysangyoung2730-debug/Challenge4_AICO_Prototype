import SwiftUI

struct HomeTutorialOverlayView: View {
    let onComplete: () -> Void

    @State private var currentStepIndex = 0

    private let steps = [
        HomeTutorialStep(
            title: "최근 기록을 확인해요",
            description: "가장 최근에 남긴 기록을 빠르게 확인할 수 있어요.",
            targetLabel: "최근 기록"
        ),
        HomeTutorialStep(
            title: "기록이 쌓이면 변화가 보여요",
            description: "이번 주 기록 수와 주목할 만한 변화를 간단히 볼 수 있어요.",
            targetLabel: "리포트"
        ),
        HomeTutorialStep(
            title: "기록에 도움이 되는 정보를 확인해요",
            description: "A/B/C 기록 방식과 보호자에게 도움이 되는 정보를 볼 수 있어요.",
            targetLabel: "정보 피드"
        ),
        HomeTutorialStep(
            title: "알림과 설정을 관리해요",
            description: "오른쪽 상단에서 알림과 설정으로 이동할 수 있어요.",
            targetLabel: "상단 아이콘"
        ),
        HomeTutorialStep(
            title: "필요한 화면으로 이동해요",
            description: "홈, 아카이브, 리포트를 하단 메뉴에서 이동할 수 있어요.",
            targetLabel: "하단 메뉴"
        ),
        HomeTutorialStep(
            title: "기록은 + 버튼에서 시작해요",
            description: "주황색 + 기록 버튼을 눌러 기록 흐름으로 이동할 수 있어요.",
            targetLabel: "+ 기록"
        )
    ]

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(steps[currentStepIndex].targetLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AICOTheme.softOrangeBackground)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 12) {
                    Text(steps[currentStepIndex].title)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(steps[currentStepIndex].description)
                        .font(.body)
                        .foregroundStyle(AICOTheme.textGray)

                    Text("\(currentStepIndex + 1) / \(steps.count)")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button("건너뛰기", action: onComplete)
                        .foregroundStyle(AICOTheme.textGray)

                    Spacer()

                    Button(isLastStep ? "완료" : "다음") {
                        if isLastStep {
                            onComplete()
                        } else {
                            currentStepIndex += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AICOTheme.primaryOrange)
                }
            }
            .padding()
            .background(AICOTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                    .stroke(AICOTheme.primaryOrange.opacity(0.25), lineWidth: 1)
            }
            .padding(AICOTheme.screenPadding)
        }
    }
}

private struct HomeTutorialStep {
    let title: String
    let description: String
    let targetLabel: String
}

#Preview {
    HomeTutorialOverlayView {}
}
