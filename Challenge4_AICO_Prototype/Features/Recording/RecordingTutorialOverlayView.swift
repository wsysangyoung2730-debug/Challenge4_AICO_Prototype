import SwiftUI

struct RecordingTutorialOverlayView: View {
    let onComplete: () -> Void

    @State private var currentIndex = 0

    private let steps = [
        RecordingTutorialStep(
            title: "상황, 행동, 대응을 나누어 기록해요",
            description: "한 번의 행동도 앞뒤 맥락을 함께 보면 다음 대응에 도움이 될 수 있어요."
        ),
        RecordingTutorialStep(
            title: "[A단계] 어떤 상황이었나요?",
            description: "행동이 나타나기 전 장소, 활동, 주변 환경을 기록해요."
        ),
        RecordingTutorialStep(
            title: "[B단계] 어떤 행동이 있었나요?",
            description: "울음, 반복 행동, 거부처럼 관찰된 행동 신호를 기록해요."
        ),
        RecordingTutorialStep(
            title: "[C단계] 어떻게 대응했고 결과는 어땠나요?",
            description: "보호자의 대응과 이후 변화를 함께 기록해요."
        ),
        RecordingTutorialStep(
            title: "필요한 항목은 직접 추가할 수 있어요",
            description: "대상자마다 다른 표현을 기록할 수 있도록 카테고리를 추가할 수 있어요."
        )
    ]

    private var currentStep: RecordingTutorialStep {
        steps[currentIndex]
    }

    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("\(currentIndex + 1) / \(steps.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AICOTheme.primaryOrange)

                VStack(spacing: 10) {
                    Text(currentStep.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(currentStep.description)
                        .font(.body)
                        .foregroundStyle(AICOTheme.textGray)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button("건너뛰기") {
                        onComplete()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(isLastStep ? "완료" : "다음") {
                        if isLastStep {
                            onComplete()
                        } else {
                            currentIndex += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AICOTheme.primaryOrange)
                }
            }
            .padding(22)
            .background(AICOTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
            .padding(AICOTheme.screenPadding)
        }
    }
}

private struct RecordingTutorialStep {
    let title: String
    let description: String
}

#Preview {
    RecordingTutorialOverlayView {}
}
