import SwiftUI

struct RecordingCompletionView: View {
    let onReturnHome: () -> Void
    let onCreateAnother: () -> Void

    var body: some View {
        VStack(spacing: AICOTheme.sectionSpacing) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(AICOTheme.primaryOrange)

            VStack(spacing: 8) {
                Text("기록이 저장되었어요.")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("저장된 기록은 이후 아카이브와 리포트에서 다시 살펴볼 수 있도록 연결할 예정이에요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    onReturnHome()
                } label: {
                    Text("홈으로 돌아가기")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AICOTheme.primaryOrange)

                Button {
                    onCreateAnother()
                } label: {
                    Text("새 기록 작성")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(AICOTheme.screenPadding)
        .background(AICOTheme.softBackground)
    }
}

#Preview {
    RecordingCompletionView(
        onReturnHome: {},
        onCreateAnother: {}
    )
}
