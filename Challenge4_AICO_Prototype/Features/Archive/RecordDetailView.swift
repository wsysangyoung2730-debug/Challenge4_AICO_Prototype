import SwiftUI

struct RecordDetailView: View {
    let record: RecordEntry
    let recipientName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                header

                detailSection(
                    title: "[A단계] 어떤 상황이었나요?",
                    categories: record.antecedentCategories
                )

                detailSection(
                    title: "[B단계] 어떤 행동이 있었나요?",
                    categories: record.behaviorCategories
                )

                detailSection(
                    title: "[C단계] 어떻게 대응했고 결과는 어땠나요?",
                    categories: record.consequenceCategories
                )

                if let note = record.note, !note.isEmpty {
                    noteSection(note)
                }

                if !record.attachmentNames.isEmpty {
                    attachmentSection
                }
            }
            .padding(AICOTheme.screenPadding)
        }
        .navigationTitle("기록 상세")
        .background(AICOTheme.softBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipientName)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(record.createdAt.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private func detailSection(title: String, categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if categories.isEmpty {
                Text("선택된 항목이 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                FlowChipLayout(items: categories)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("자유 메모")
                .font(.headline)

            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("첨부 사진")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(record.attachmentNames, id: \.self) { fileName in
                        if let image = ImageStorageService.image(for: fileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                        } else {
                            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                                .fill(AICOTheme.softOrangeBackground)
                                .frame(width: 96, height: 96)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(AICOTheme.primaryOrange)
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }
}

private struct FlowChipLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AICOTheme.primaryOrange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}
