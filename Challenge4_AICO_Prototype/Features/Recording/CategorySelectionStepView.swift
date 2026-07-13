import SwiftUI

struct CategorySelectionStepView: View {
    let stage: RecordCategoryStage
    let title: String
    let helperText: String
    let categories: [RecordCategory]
    @Binding var selectedNames: Set<String>
    let onAddCategory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(helperText)
                    .font(.body)
                    .foregroundStyle(AICOTheme.textGray)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                ForEach(categories) { category in
                    categoryChip(category)
                }

                Button {
                    onAddCategory()
                } label: {
                    Label("추가", systemImage: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.bordered)
                .tint(AICOTheme.primaryOrange)
            }
            Text(selectedNames.isEmpty ? "항목을 선택하면 아래에서 다음 단계로 이동할 수 있어요." : "\(selectedNames.count)개 선택됨")
                .font(.footnote)
                .fontWeight(selectedNames.isEmpty ? .regular : .semibold)
                .foregroundStyle(selectedNames.isEmpty ? AICOTheme.textGray : AICOTheme.primaryOrange)
        }
    }

    private func categoryChip(_ category: RecordCategory) -> some View {
        let isSelected = selectedNames.contains(category.name)

        return Button {
            if isSelected {
                selectedNames.remove(category.name)
            } else {
                selectedNames.insert(category.name)
            }
        } label: {
            Text(category.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .background(isSelected ? AICOTheme.primaryOrange : AICOTheme.cardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay {
                    RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                        .stroke(isSelected ? AICOTheme.primaryOrange : AICOTheme.cardGray, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
