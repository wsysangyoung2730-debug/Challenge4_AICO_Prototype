import SwiftUI

struct ArchiveFilterView: View {
    @Binding var selectedDateFilter: ArchiveDateFilter
    @Binding var selectedStageFilter: ArchiveStageFilter
    @Binding var selectedCategoryName: String?

    let availableCategoryNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            filterSection(title: "날짜") {
                Picker("날짜", selection: $selectedDateFilter) {
                    ForEach(ArchiveDateFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            filterSection(title: "카테고리 단계") {
                Picker("카테고리 단계", selection: $selectedStageFilter) {
                    ForEach(ArchiveStageFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !availableCategoryNames.isEmpty {
                filterSection(title: "세부 카테고리") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip(title: "전체", categoryName: nil)

                            ForEach(availableCategoryNames, id: \.self) { name in
                                categoryChip(title: name, categoryName: name)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func categoryChip(title: String, categoryName: String?) -> some View {
        let isSelected = selectedCategoryName == categoryName

        return Button {
            selectedCategoryName = categoryName
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AICOTheme.primaryOrange : AICOTheme.softOrangeBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
