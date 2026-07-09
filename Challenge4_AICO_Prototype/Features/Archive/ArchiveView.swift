import SwiftUI

struct ArchiveView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                Text("아카이브")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                PlaceholderCardView(
                    title: "기록 보관함",
                    message: "저장된 기록 카드와 필터는 이후 단계에서 구현됩니다.",
                    systemImage: "archivebox.fill"
                )

                Spacer()
            }
            .padding(AICOTheme.screenPadding)
            .navigationTitle("아카이브")
            .background(AICOTheme.softBackground)
        }
    }
}

#Preview {
    ArchiveView()
}
