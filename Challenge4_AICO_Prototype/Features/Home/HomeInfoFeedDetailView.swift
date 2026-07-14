import SwiftUI

struct HomeInfoFeedDetailView: View {
    let item: HomeInfoFeedItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                    Image(systemName: item.systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(AICOTheme.primaryOrange)

                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(item.detail)
                        .font(.body)
                        .foregroundStyle(AICOTheme.textGray)
                }
                .padding(AICOTheme.screenPadding)
            }
            .navigationTitle("정보")
            .navigationBarTitleDisplayMode(.inline)
            .background(AICOTheme.softBackground)
        }
    }
}

struct HomeInfoFeedItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let summary: String
    let detail: String
    let systemImage: String
}
