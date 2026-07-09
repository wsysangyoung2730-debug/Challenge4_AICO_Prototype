import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("AICO")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Warm caregiver support prototype")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Records")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("ABC records will appear here after recipient registration.")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Report")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Record count, notable changes, and A/B/C Top 3 summaries are planned for this area.")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
            .navigationTitle(AppConstants.appName)
        }
    }
}

#Preview {
    HomeView()
}
