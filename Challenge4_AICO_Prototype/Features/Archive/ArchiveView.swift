import SwiftData
import SwiftUI

struct ArchiveView: View {
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]

    @State private var selectedDateFilter: ArchiveDateFilter = .all
    @State private var selectedStageFilter: ArchiveStageFilter = .all
    @State private var selectedCategoryName: String?

    private var dateFilteredRecords: [RecordEntry] {
        records.filter { selectedDateFilter.contains($0.createdAt) }
    }

    private var stageFilteredRecords: [RecordEntry] {
        dateFilteredRecords.filter { selectedStageFilter.contains($0) }
    }

    private var filteredRecords: [RecordEntry] {
        guard let selectedCategoryName else {
            return stageFilteredRecords
        }

        return stageFilteredRecords.filter {
            selectedStageFilter.contains($0, categoryName: selectedCategoryName)
        }
    }

    private var availableCategoryNames: [String] {
        let names = stageFilteredRecords.flatMap { selectedStageFilter.categoryNames(in: $0) }
        return Array(Set(names)).sorted()
    }

    private var resultSummary: String {
        if filteredRecords.isEmpty {
            return records.isEmpty ? "저장된 기록이 아직 없어요." : "조건에 맞는 기록이 없어요."
        }

        if selectedDateFilter == .all && selectedStageFilter == .all && selectedCategoryName == nil {
            return "총 \(filteredRecords.count)개의 기록이 있어요."
        }

        return "조건에 맞는 기록 \(filteredRecords.count)개를 찾았어요."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                if records.isEmpty {
                    emptyState
                } else {
                    ArchiveFilterView(
                        selectedDateFilter: $selectedDateFilter,
                        selectedStageFilter: $selectedStageFilter,
                        selectedCategoryName: $selectedCategoryName,
                        availableCategoryNames: availableCategoryNames
                    )

                    Text(resultSummary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(filteredRecords.isEmpty ? .secondary : AICOTheme.primaryOrange)

                    if filteredRecords.isEmpty {
                        filteredEmptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecords) { record in
                                NavigationLink {
                                    RecordDetailView(
                                        record: record,
                                        recipientName: recipientName(for: record)
                                    )
                                } label: {
                                    ArchiveRecordCardView(
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
            .padding(AICOTheme.screenPadding)
        }
        .navigationTitle("아카이브")
        .navigationBarTitleDisplayMode(.inline)
        .background(AICOTheme.softBackground)
        .onChange(of: selectedStageFilter) {
            selectedCategoryName = nil
        }
        .onChange(of: selectedDateFilter) {
            selectedCategoryName = nil
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "archivebox")
                .font(.largeTitle)
                .foregroundStyle(AICOTheme.primaryOrange)

            VStack(alignment: .leading, spacing: 6) {
                Text("아직 저장된 기록이 없어요.")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("+ 기록 버튼을 눌러 첫 기록을 남기면 이곳에서 다시 확인할 수 있어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text("기록 시작하기")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AICOTheme.primaryOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AICOTheme.primaryOrange.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var filteredEmptyState: some View {
        PlaceholderCardView(
            title: "조건에 맞는 기록이 없어요.",
            message: "필터를 바꾸면 다른 기록을 확인할 수 있어요.",
            systemImage: "line.3.horizontal.decrease.circle"
        )
    }

    private func recipientName(for record: RecordEntry) -> String {
        recipients.first { $0.id == record.recipientId }?.nickname ?? "등록된 대상자"
    }
}

enum ArchiveDateFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case oneWeek = "1주"
    case oneMonth = "1개월"
    case threeMonths = "3개월"

    var id: Self { self }

    func contains(_ date: Date) -> Bool {
        guard self != .all else { return true }

        let calendar = Calendar.current
        let now = Date()
        let startDate: Date?

        switch self {
        case .all:
            startDate = nil
        case .oneWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)
        }

        guard let startDate else { return true }
        return date >= startDate && date <= now
    }
}

enum ArchiveStageFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case antecedent = "A단계"
    case behavior = "B단계"
    case consequence = "C단계"

    var id: Self { self }

    func contains(_ record: RecordEntry) -> Bool {
        switch self {
        case .all:
            true
        case .antecedent:
            !record.antecedentCategories.isEmpty
        case .behavior:
            !record.behaviorCategories.isEmpty
        case .consequence:
            !record.consequenceCategories.isEmpty
        }
    }

    func contains(_ record: RecordEntry, categoryName: String) -> Bool {
        switch self {
        case .all:
            record.antecedentCategories.contains(categoryName)
                || record.behaviorCategories.contains(categoryName)
                || record.consequenceCategories.contains(categoryName)
        case .antecedent:
            record.antecedentCategories.contains(categoryName)
        case .behavior:
            record.behaviorCategories.contains(categoryName)
        case .consequence:
            record.consequenceCategories.contains(categoryName)
        }
    }

    func categoryNames(in record: RecordEntry) -> [String] {
        switch self {
        case .all:
            record.antecedentCategories + record.behaviorCategories + record.consequenceCategories
        case .antecedent:
            record.antecedentCategories
        case .behavior:
            record.behaviorCategories
        case .consequence:
            record.consequenceCategories
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveView()
    }
    .modelContainer(SwiftDataContainer.shared)
}
