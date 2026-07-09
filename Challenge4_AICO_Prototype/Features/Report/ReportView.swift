import SwiftUI

struct ReportView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            Text("리포트")
                .font(.largeTitle)
                .fontWeight(.bold)

            PlaceholderCardView(
                title: "주간 요약",
                message: "이번 주 기록 수, 주목할 변화, A/B/C Top 3가 표시될 예정입니다.",
                systemImage: "chart.pie.fill"
            )

            Spacer()
        }
        .padding(AICOTheme.screenPadding)
        .navigationTitle("리포트")
        .background(AICOTheme.softBackground)
    }
}

#Preview {
    ReportView()
}
