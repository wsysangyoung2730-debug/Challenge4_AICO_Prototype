import SwiftUI

struct CategorySelectionStepView: View {
    let stage: RecordCategoryStage
    let title: String
    let helperText: String
    let categories: [RecordCategory]
    @Binding var selectedNames: Set<String>
    let onAddCategory: () -> Void

    private let consequenceResponseNames = ["음식/음료 제공", "휴식 제공", "공간 이동", "안아줌", "거리둠", "그림/시각자료", "활동 전환"]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                titleView

                Text(helperText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            categoryContent

        }
    }

    private var titleView: some View {
        Text(title)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var categoryContent: some View {
        if stage == .consequence {
            VStack(alignment: .leading, spacing: 28) {
                categoryGroup(title: "보호자 대응", categories: responseCategories, showsAddButton: true)
                categoryGroup(title: "대응 결과", categories: resultCategories, showsAddButton: false)
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                requiredLabel(stage == .antecedent ? "선행 상황" : "관찰 행동")

                TagFlowLayout(horizontalSpacing: 10, verticalSpacing: 12) {
                    ForEach(categories) { category in
                        categoryChip(category)
                    }

                    addCategoryButton
                }
            }
        }
    }

    private func categoryGroup(title: String, categories: [RecordCategory], showsAddButton: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            requiredLabel(title)

            TagFlowLayout(horizontalSpacing: 10, verticalSpacing: 12) {
                ForEach(categories) { category in
                    categoryChip(category)
                }

                if showsAddButton {
                    addCategoryButton
                }
            }
        }
    }

    private func requiredLabel(_ title: String) -> some View {
        (Text(title).foregroundStyle(.primary) + Text(" *").foregroundStyle(AICOTheme.primaryOrange))
            .font(.system(size: 16, weight: .semibold))
    }

    private var responseCategories: [RecordCategory] {
        categories.filter { consequenceResponseNames.contains($0.name) || $0.isCustom }
    }

    private var resultCategories: [RecordCategory] {
        categories.filter { !consequenceResponseNames.contains($0.name) && !$0.isCustom }
    }

    private var addCategoryButton: some View {
        Button {
            onAddCategory()
        } label: {
            Label("태그 추가", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color(red: 0.918, green: 0.918, blue: 0.918))
                .foregroundStyle(AICOTheme.textGray)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(isSelected ? AICOTheme.primaryOrange : Color.clear)
                .foregroundStyle(isSelected ? .white : Color.secondary)
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule()
                            .stroke(Color(red: 0.855, green: 0.855, blue: 0.855), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct TagFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        let rows = rows(in: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { partialResult, row in
            partialResult + row.height
        } + CGFloat(max(rows.count - 1, 0)) * verticalSpacing

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(in: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }

            y += row.height + verticalSpacing
        }
    }

    private func rows(in maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentItems: [Row.Item] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = min(size.width, maxWidth)
            let item = Row.Item(subview: subview, size: CGSize(width: itemWidth, height: size.height))
            let proposedWidth = currentItems.isEmpty ? itemWidth : currentWidth + horizontalSpacing + itemWidth

            if proposedWidth > maxWidth, !currentItems.isEmpty {
                rows.append(Row(items: currentItems, height: currentHeight))
                currentItems = [item]
                currentWidth = itemWidth
                currentHeight = size.height
            } else {
                currentItems.append(item)
                currentWidth = proposedWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(Row(items: currentItems, height: currentHeight))
        }

        return rows
    }

    private struct Row {
        let items: [Item]
        let height: CGFloat

        struct Item {
            let subview: LayoutSubview
            let size: CGSize
        }
    }
}
