import SwiftData
import SwiftUI

struct ReportView: View {
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]
    @State private var selectedPeriod: ReportPeriod = .weekly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                header

                Picker("리포트 기간", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                if currentRecords.isEmpty {
                    ReportEmptyStateView(message: selectedPeriod.emptyMessage)
                } else {
                    periodContent
                }
            }
            .padding(AICOTheme.screenPadding)
        }
        .navigationTitle("리포트")
        .background(AICOTheme.softBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("리포트")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("기록상 자주 나타난 흐름을 차분히 돌아봐요.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var periodContent: some View {
        switch selectedPeriod {
        case .daily:
            dailyReport
        case .weekly:
            weeklyReport
        case .monthly:
            monthlyReport
        }
    }

    private var dailyReport: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            ReportMetricCardView(
                title: "오늘의 요약",
                value: "\(currentRecords.count)개",
                caption: dailySummaryText,
                systemImage: "sun.max.fill"
            )

            notableChangeCard(title: "오늘 특이사항", records: currentRecords)
            topCategoriesSection(records: currentRecords)
            categoryBars(records: currentRecords)
        }
    }

    private var weeklyReport: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            ReportMetricCardView(
                title: "이번 주 총 기록 수",
                value: "\(currentRecords.count)개",
                caption: weeklyPatternText,
                systemImage: "calendar.badge.clock"
            )

            dayBars
            topCategoriesSection(records: currentRecords)
            notableChangeCard(title: "주목할 만한 변화", records: currentRecords)
            repeatedCombinationCard(records: currentRecords)
        }
    }

    private var monthlyReport: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            ReportMetricCardView(
                title: "이번 달 총 기록 수",
                value: "\(currentRecords.count)개",
                caption: monthlyComparisonText,
                systemImage: "calendar"
            )

            weekBars
            topCategoriesSection(records: currentRecords)
            repeatedCombinationCard(records: currentRecords)
            nextMonthReferenceCard
        }
    }

    private var currentRecords: [RecordEntry] {
        records.filter { selectedPeriod.contains($0.createdAt) }
    }

    private var previousPeriodRecords: [RecordEntry] {
        records.filter { selectedPeriod.containsPreviousPeriod($0.createdAt) }
    }

    private var dailySummaryText: String {
        if let top = ReportCalculator.topItems(in: currentRecords.flatMap(\.behaviorCategories), limit: 1).first {
            return "오늘은 \(top.name)이 가장 자주 반복 기록되었어요. 함께 확인해보세요."
        }
        return "오늘 기록된 내용을 A/B/C 단계로 다시 확인할 수 있어요."
    }

    private var weeklyPatternText: String {
        if let topBehavior = ReportCalculator.topItems(in: currentRecords.flatMap(\.behaviorCategories), limit: 1).first {
            return "이번 주에는 \(topBehavior.name)이 가장 자주 기록되었어요."
        }
        return "이번 주 기록 흐름을 단계별로 살펴볼 수 있어요."
    }

    private var monthlyComparisonText: String {
        guard !previousPeriodRecords.isEmpty else {
            return "비교할 지난달 기록이 아직 부족해요."
        }

        let difference = currentRecords.count - previousPeriodRecords.count
        if difference > 0 {
            return "지난달보다 기록 수가 \(difference)개 늘었어요."
        } else if difference < 0 {
            return "지난달보다 기록 수가 \(abs(difference))개 줄었어요."
        }
        return "지난달과 기록 수가 비슷해요."
    }

    private var dayBars: some View {
        ReportCard(title: "요일별 기록 수") {
            VStack(spacing: 10) {
                ForEach(ReportCalculator.weekdayCounts(records: currentRecords), id: \.label) { item in
                    ReportBarRowView(label: item.label, count: item.count, maxCount: item.maxCount)
                }
            }
        }
    }

    private var weekBars: some View {
        ReportCard(title: "주차별 기록 수") {
            VStack(spacing: 10) {
                ForEach(ReportCalculator.weekOfMonthCounts(records: currentRecords), id: \.label) { item in
                    ReportBarRowView(label: item.label, count: item.count, maxCount: item.maxCount)
                }
            }
        }
    }

    private func topCategoriesSection(records: [RecordEntry]) -> some View {
        ReportCard(title: "A/B/C Top 3") {
            VStack(spacing: 12) {
                ReportTopCategoryRow(title: "A단계", items: ReportCalculator.topItems(in: records.flatMap(\.antecedentCategories)))
                ReportTopCategoryRow(title: "B단계", items: ReportCalculator.topItems(in: records.flatMap(\.behaviorCategories)))
                ReportTopCategoryRow(title: "C단계", items: ReportCalculator.topItems(in: records.flatMap(\.consequenceCategories)))
            }
        }
    }

    private func categoryBars(records: [RecordEntry]) -> some View {
        ReportCard(title: "오늘 A/B/C 흐름") {
            VStack(spacing: 10) {
                ReportBarRowView(label: "A단계", count: records.flatMap(\.antecedentCategories).count, maxCount: maxStageCount(records))
                ReportBarRowView(label: "B단계", count: records.flatMap(\.behaviorCategories).count, maxCount: maxStageCount(records))
                ReportBarRowView(label: "C단계", count: records.flatMap(\.consequenceCategories).count, maxCount: maxStageCount(records))
            }
        }
    }

    private func maxStageCount(_ records: [RecordEntry]) -> Int {
        [
            records.flatMap(\.antecedentCategories).count,
            records.flatMap(\.behaviorCategories).count,
            records.flatMap(\.consequenceCategories).count,
            1
        ].max() ?? 1
    }

    private func notableChangeCard(title: String, records: [RecordEntry]) -> some View {
        ReportCard(title: title) {
            VStack(alignment: .leading, spacing: 8) {
                Text(notableText(records: records))
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("이 내용은 기록 빈도를 요약한 것이며 의료적 판단이 아니에요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func notableText(records: [RecordEntry]) -> String {
        let topA = ReportCalculator.topItems(in: records.flatMap(\.antecedentCategories), limit: 1).first?.name
        let topB = ReportCalculator.topItems(in: records.flatMap(\.behaviorCategories), limit: 1).first?.name
        let topC = ReportCalculator.topItems(in: records.flatMap(\.consequenceCategories), limit: 1).first?.name

        if let topB {
            return "\(topB)이 기록상 자주 나타났어요. 앞뒤 상황과 대응을 함께 확인해보세요."
        }
        if let topA {
            return "\(topA) 상황에서 기록이 반복되었어요."
        }
        if let topC {
            return "\(topC) 대응이 자주 선택되었어요."
        }
        return "아직 주목할 만한 반복 기록을 만들 데이터가 부족해요."
    }

    private func repeatedCombinationCard(records: [RecordEntry]) -> some View {
        ReportCard(title: "반복된 조합") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ReportCalculator.topCombinations(records: records), id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)회")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(AICOTheme.primaryOrange)
                    }
                }

                if ReportCalculator.topCombinations(records: records).isEmpty {
                    Text("반복 조합을 보려면 기록이 조금 더 필요해요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var nextMonthReferenceCard: some View {
        ReportCard(title: "다음 달 참고") {
            Text("자주 기록된 상황을 다음 달에도 함께 확인해보세요.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private enum ReportPeriod: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: Self { self }

    var title: String {
        switch self {
        case .daily: "일일"
        case .weekly: "주간"
        case .monthly: "월간"
        }
    }

    var emptyMessage: String {
        switch self {
        case .daily: "오늘 리포트를 만들 기록이 아직 없어요."
        case .weekly: "이번 주 리포트를 만들 기록이 아직 부족해요."
        case .monthly: "이번 달 리포트를 만들 기록이 아직 부족해요."
        }
    }

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .daily:
            return calendar.isDateInToday(date)
        case .weekly:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
    }

    func containsPreviousPeriod(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .daily:
            guard let previous = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
            return calendar.isDate(date, inSameDayAs: previous)
        case .weekly:
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: previous, toGranularity: .weekOfYear)
        case .monthly:
            guard let previous = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: previous, toGranularity: .month)
        }
    }
}

private enum ReportCalculator {
    static func topItems(in names: [String], limit: Int = 3) -> [ReportCountItem] {
        Dictionary(grouping: names, by: { $0 })
            .map { ReportCountItem(name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.name < $1.name
                }
                return $0.count > $1.count
            }
            .prefix(limit)
            .map { $0 }
    }

    static func weekdayCounts(records: [RecordEntry]) -> [ReportBarItem] {
        let labels = ["일", "월", "화", "수", "목", "금", "토"]
        let calendar = Calendar.current
        let counts = Dictionary(grouping: records) { record in
            calendar.component(.weekday, from: record.createdAt) - 1
        }
        let maxCount = max(counts.values.map(\.count).max() ?? 0, 1)

        return labels.indices.map { index in
            ReportBarItem(label: labels[index], count: counts[index]?.count ?? 0, maxCount: maxCount)
        }
    }

    static func weekOfMonthCounts(records: [RecordEntry]) -> [ReportBarItem] {
        let calendar = Calendar.current
        let counts = Dictionary(grouping: records) { record in
            calendar.component(.weekOfMonth, from: record.createdAt)
        }
        let maxCount = max(counts.values.map(\.count).max() ?? 0, 1)

        return (1...5).map { week in
            ReportBarItem(label: "\(week)주차", count: counts[week]?.count ?? 0, maxCount: maxCount)
        }
    }

    static func topCombinations(records: [RecordEntry]) -> [ReportCountItem] {
        let combinations = records.flatMap { record in
            [
                combine(prefix: "A+B", first: record.antecedentCategories.first, second: record.behaviorCategories.first),
                combine(prefix: "B+C", first: record.behaviorCategories.first, second: record.consequenceCategories.first)
            ]
            .compactMap { $0 }
        }

        return topItems(in: combinations, limit: 3)
    }

    private static func combine(prefix: String, first: String?, second: String?) -> String? {
        guard let first, let second else { return nil }
        return "\(prefix): \(first) + \(second)"
    }
}

private struct ReportCountItem {
    let name: String
    let count: Int
}

private struct ReportBarItem {
    let label: String
    let count: Int
    let maxCount: Int
}

private struct ReportMetricCardView: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 34, height: 34)
                .background(AICOTheme.primaryOrange.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AICOTheme.primaryOrange)
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }
}

private struct ReportCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }
}

private struct ReportTopCategoryRow: View {
    let title: String
    let items: [ReportCountItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(AICOTheme.primaryOrange)

            if items.isEmpty {
                Text("아직 선택된 항목이 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(items, id: \.name) { item in
                        Text("\(item.name) \(item.count)회")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AICOTheme.softOrangeBackground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

private struct ReportBarRowView: View {
    let label: String
    let count: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 46, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(AICOTheme.primaryOrange)
                        .frame(width: max(6, proxy.size.width * CGFloat(count) / CGFloat(max(maxCount, 1))))
                }
            }
            .frame(height: 9)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

private struct ReportEmptyStateView: View {
    let message: String

    var body: some View {
        PlaceholderCardView(
            title: "아직 리포트를 만들 기록이 부족해요.",
            message: message,
            systemImage: "chart.bar.doc.horizontal"
        )
    }
}

#Preview {
    ReportView()
        .modelContainer(SwiftDataContainer.shared)
}
