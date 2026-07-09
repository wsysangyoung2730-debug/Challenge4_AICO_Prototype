import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]

    @State private var selectedInfoItem: HomeInfoFeedItem?

    private var recentRecords: [RecordEntry] {
        Array(records.prefix(5))
    }

    private var weeklyRecordCount: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    private var weeklyRecords: [RecordEntry] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    private var weeklyTopBehavior: String {
        let names = weeklyRecords.flatMap(\.behaviorCategories)
        let top = Dictionary(grouping: names, by: { $0 })
            .map { (name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.name < $1.name
                }
                return $0.count > $1.count
            }
            .first

        return top.map { "\($0.name)이 자주 기록되었어요" } ?? "기록이 쌓이면 표시됩니다"
    }

    private let feedItems = [
        HomeInfoFeedItem(
            title: "A/B/C 기록이란?",
            summary: "상황, 행동, 대응을 나누어 기록하는 방식이에요.",
            detail: "A는 행동 전 상황, B는 관찰된 행동이나 신호, C는 이후 대응과 결과를 뜻합니다. AICO는 이 흐름을 보호자가 부담 없이 정리할 수 있게 돕는 방향으로 설계하고 있습니다.",
            systemImage: "list.clipboard.fill"
        ),
        HomeInfoFeedItem(
            title: "기록이 쌓이면 어떤 점을 볼 수 있을까요?",
            summary: "반복되는 맥락과 반응 변화를 돌아볼 수 있어요.",
            detail: "기록이 충분히 쌓이면 아카이브와 리포트에서 자주 나타나는 상황, 행동, 대응을 다시 확인할 수 있습니다. Phase 2에서는 정보 구조만 검증합니다.",
            systemImage: "chart.bar.fill"
        ),
        HomeInfoFeedItem(
            title: "보호자 간 기록을 공유하기 전 확인할 점",
            summary: "공유 기능은 추후 별도 범위로 설계합니다.",
            detail: "민감한 정보가 포함될 수 있으므로 공유 방식은 신중히 설계되어야 합니다. 현재 프로토타입에서는 공유 기능을 구현하지 않습니다.",
            systemImage: "person.2.fill"
        )
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    recentRecordsSection
                    reportPreviewSection
                    informationFeedSection
                }
            }
            .background(AICOTheme.softBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "bell")
                    }
                    .accessibilityLabel("알림")

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("설정")
                }
            }

            if !sessionState.hasSeenHomeTutorial {
                HomeTutorialOverlayView {
                    sessionState.completeHomeTutorial()
                }
            }
        }
        .sheet(item: $selectedInfoItem) { item in
            HomeInfoFeedDetailView(item: item)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image("AICOLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AICOTheme.primaryOrange.opacity(0.12), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppConstants.appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(AICOTheme.primaryOrange)

                    Text("보호자를 위한 따뜻한 기록 도우미")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("안녕하세요")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("오늘의 기록을 가볍게 확인해볼까요?")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, AICOTheme.screenPadding)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.softBackground)
    }

    private var recentRecordsSection: some View {
        DashboardSection(
            label: "01",
            title: "최근 기록",
            subtitle: "최근 5개의 기록을 빠르게 확인해요",
            background: AICOTheme.cardBackground
        ) {
            if recentRecords.isEmpty {
                PlaceholderCardView(
                    title: "아직 기록이 없어요",
                    message: "기록을 시작하면 최근 기록이 이곳에 보여요.",
                    systemImage: "clock.fill"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(recentRecords) { record in
                        NavigationLink {
                            RecordDetailView(
                                record: record,
                                recipientName: recipientName(for: record)
                            )
                        } label: {
                            RecentRecordPreviewCard(
                                record: record,
                                recipientName: recipientName(for: record)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var reportPreviewSection: some View {
        DashboardSection(
            label: "02",
            title: "간단 리포트",
            subtitle: "이번 주 흐름을 미리 살펴봐요",
            background: AICOTheme.reportBackground
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("이번 주 총 기록 수")
                        .font(.headline)

                    Spacer()

                    Text("\(weeklyRecordCount)개")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AICOTheme.primaryOrange)
                }

                Divider()

                ReportPreviewRow(title: "주목할 만한 변화", value: weeklyTopBehavior)
                ReportPreviewRow(title: "A/B/C Top 3", value: "리포트에서 자세히 확인해요")

                NavigationLink {
                    ReportView()
                } label: {
                    Text("리포트 보기")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AICOTheme.primaryOrange)
                }
            }
            .padding()
            .background(AICOTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
        }
    }

    private var informationFeedSection: some View {
        DashboardSection(
            label: "03",
            title: "정보 피드",
            subtitle: "기록에 도움이 되는 내용을 확인해요",
            background: AICOTheme.feedBackground
        ) {
            VStack(spacing: 10) {
                ForEach(feedItems) { item in
                    Button {
                        selectedInfoItem = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.systemImage)
                                .foregroundStyle(AICOTheme.primaryOrange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(item.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(AICOTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recipientName(for record: RecordEntry) -> String {
        recipients.first { $0.id == record.recipientId }?.nickname ?? "등록된 대상자"
    }

}

private struct DashboardSection<Content: View>: View {
    let label: String
    let title: String
    let subtitle: String
    let background: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(width: 34, height: 34)
                    .background(AICOTheme.primaryOrange.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            content
        }
        .padding(AICOTheme.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
    }
}

private struct RecentRecordPreviewCard: View {
    let record: RecordEntry
    let recipientName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipientName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(mainBehavior)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AICOTheme.primaryOrange.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(categorySummary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var mainBehavior: String {
        record.behaviorCategories.first ?? "B단계 없음"
    }

    private var categorySummary: String {
        let antecedent = record.antecedentCategories.prefix(2).joined(separator: ", ")
        let behavior = record.behaviorCategories.prefix(2).joined(separator: ", ")
        let consequence = record.consequenceCategories.prefix(2).joined(separator: ", ")

        let summary = [
            antecedent.isEmpty ? nil : "A: \(antecedent)",
            behavior.isEmpty ? nil : "B: \(behavior)",
            consequence.isEmpty ? nil : "C: \(consequence)"
        ]
        .compactMap { $0 }
        .joined(separator: " / ")

        return summary.isEmpty ? "A/B/C 카테고리 없음" : summary
    }
}

private struct ReportPreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AnonymousSessionState())
        .modelContainer(SwiftDataContainer.shared)
}
