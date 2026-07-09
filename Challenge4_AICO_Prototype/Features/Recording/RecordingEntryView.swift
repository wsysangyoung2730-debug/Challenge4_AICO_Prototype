import SwiftUI

struct RecordingEntryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            Text("기록하기")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A/B/C 기록 흐름은 다음 단계에서 구현됩니다.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
            } label: {
                Text("기록 시작하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AICOTheme.primaryOrange)

            Spacer()
        }
        .padding(AICOTheme.screenPadding)
        .navigationTitle("기록")
        .background(AICOTheme.softBackground)
    }
}

#Preview {
    RecordingEntryView()
}
