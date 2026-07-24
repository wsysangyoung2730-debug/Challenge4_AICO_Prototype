import SwiftData
import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]

    @State private var selectedStageFilter: ArchiveStageFilter = .antecedent
    @State private var selectedCategoryName: String?
    @State private var sortOrder: ArchiveSortOrder = .newest

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var stageFilteredRecords: [RecordEntry] {
        records.filter {
            $0.recipientId == selectedRecipient?.id && selectedStageFilter.contains($0)
        }
    }

    private var selectedRecipient: RecipientProfile? {
        recipients.first { $0.id == sessionState.selectedRecipientID } ?? recipients.first
    }

    private var filteredRecords: [RecordEntry] {
        let filtered = stageFilteredRecords.filter { record in
            guard let selectedCategoryName else { return true }
            return selectedStageFilter.contains(record, categoryName: selectedCategoryName)
        }

        return filtered.sorted {
            switch sortOrder {
            case .newest:
                $0.createdAt > $1.createdAt
            case .oldest:
                $0.createdAt < $1.createdAt
            }
        }
    }

    private var availableCategoryNames: [String] {
        Array(Set(stageFilteredRecords.flatMap { selectedStageFilter.categoryNames(in: $0) })).sorted()
    }

    var body: some View {
        ZStack {
            AICOTheme.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    HStack(alignment: .center) {
                        Text("기록 보관함")
                            .font(.system(size: 28, weight: .semibold))

                        Spacer()

                        stagePicker
                    }

                    categoryFilter

                    HStack {
                        Text("총 \(filteredRecords.count)건")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        sortMenu
                    }

                    recordsContent
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedStageFilter) {
            selectedCategoryName = nil
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("AICOStar")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            Spacer()

            MainHeaderActions(recipients: recipients)
        }
    }

    private var stagePicker: some View {
        Picker("기록 단계", selection: $selectedStageFilter) {
            ForEach(ArchiveStageFilter.archiveCases) { filter in
                Text(filter.shortTitle).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 104)
    }

    @ViewBuilder
    private var categoryFilter: some View {
        if !availableCategoryNames.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableCategoryNames, id: \.self) { name in
                        categoryChip(name)
                    }
                }
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
    }

    private func categoryChip(_ name: String) -> some View {
        let isSelected = selectedCategoryName == name

        return Button {
            selectedCategoryName = isSelected ? nil : name
        } label: {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? Color.white : AICOTheme.textGray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AICOTheme.primaryOrange : Color.clear)
                .overlay {
                    if !isSelected {
                        Capsule().stroke(Color(.separator), lineWidth: 1)
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sortMenu: some View {
        Menu {
            Picker("정렬", selection: $sortOrder) {
                ForEach(ArchiveSortOrder.allCases) { order in
                    Text(order.rawValue).tag(order)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(sortOrder.rawValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(AICOTheme.textGray)
            .fixedSize(horizontal: true, vertical: false)
            .frame(width: 76, alignment: .trailing)
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var recordsContent: some View {
        if records.isEmpty {
            emptyState
        } else if filteredRecords.isEmpty {
            PlaceholderCardView(
                title: "조건에 맞는 기록이 없어요.",
                message: "단계나 카테고리를 바꾸면 다른 기록을 확인할 수 있어요.",
                systemImage: "line.3.horizontal.decrease.circle"
            )
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredRecords) { record in
                    NavigationLink {
                        RecordDetailView(record: record)
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

    private var emptyState: some View {
        PlaceholderCardView(
            title: "아직 저장된 기록이 없어요.",
            message: "+ 기록 버튼을 눌러 첫 기록을 남겨보세요.",
            systemImage: "archivebox"
        )
    }

    private func recipientName(for record: RecordEntry) -> String {
        recipient(for: record)?.nickname ?? "등록된 대상자"
    }

    private func recipient(for record: RecordEntry) -> RecipientProfile? {
        recipients.first { $0.id == record.recipientId }
    }
}

enum ArchiveSortOrder: String, CaseIterable, Identifiable {
    case newest = "최신순"
    case oldest = "오래된순"

    var id: Self { self }
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

    static let archiveCases: [ArchiveStageFilter] = [.antecedent, .behavior, .consequence]

    var id: Self { self }

    var shortTitle: String {
        switch self {
        case .all: "전체"
        case .antecedent: "A"
        case .behavior: "B"
        case .consequence: "C"
        }
    }

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
