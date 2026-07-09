import SwiftUI

struct PlaceholderCardView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(AICOTheme.primaryOrange)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                .stroke(AICOTheme.primaryOrange.opacity(0.12))
        }
    }
}

#Preview {
    PlaceholderCardView(
        title: "최근 기록",
        message: "저장한 기록이 이곳에 표시됩니다.",
        systemImage: "clock.fill"
    )
    .padding()
    .background(AICOTheme.softBackground)
}
