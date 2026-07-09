import SwiftUI

struct RecordingCompletionView: View {
    let onReturnHome: () -> Void
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AICOTheme.sectionSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AICOTheme.primaryOrange.opacity(0.14))
                    .frame(width: isAnimating ? 112 : 76, height: isAnimating ? 112 : 76)
                    .opacity(isAnimating ? 0 : 1)

                Circle()
                    .fill(AICOTheme.primaryOrange.opacity(0.16))
                    .frame(width: 92, height: 92)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .scaleEffect(isAnimating ? 1 : 0.72)
            }
            .animation(.easeOut(duration: 0.65), value: isAnimating)

            VStack(spacing: 8) {
                Text("기록이 저장되었어요.")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("저장된 기록은 이후 아카이브와 리포트에서 다시 살펴볼 수 있도록 연결할 예정이에요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onReturnHome()
            } label: {
                Text("홈으로 돌아가기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AICOTheme.primaryOrange)

            Spacer()
        }
        .padding(AICOTheme.screenPadding)
        .background(AICOTheme.softBackground)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    RecordingCompletionView(onReturnHome: {})
}
