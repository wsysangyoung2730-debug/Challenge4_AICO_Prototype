import SwiftData
import SwiftUI

struct ABCRecordingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    let recipient: RecipientProfile

    @State private var stepIndex = 0
    @State private var selectedAntecedents: Set<String> = []
    @State private var selectedBehaviors: Set<String> = []
    @State private var selectedConsequences: Set<String> = []
    @State private var note = ""
    @State private var includeAttachmentPlaceholder = false
    @State private var categoryInputStage: RecordCategoryStage?
    @State private var newCategoryName = ""
    @State private var savedRecord: RecordEntry?

    private let steps = RecordingStep.allCases

    var body: some View {
        Group {
            if savedRecord != nil {
                RecordingCompletionView(
                    onReturnHome: { dismiss() },
                    onCreateAnother: { resetFlow() }
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                        header
                        progressBar
                        currentStepContent
                        navigationButtons
                    }
                    .padding(AICOTheme.screenPadding)
                }
            }
        }
        .background(AICOTheme.softBackground)
        .alert("카테고리 추가", isPresented: categoryInputBinding) {
            TextField("새 카테고리 이름", text: $newCategoryName)

            Button("취소", role: .cancel) {
                newCategoryName = ""
                categoryInputStage = nil
            }

            Button("추가") {
                saveCustomCategory()
            }
        } message: {
            Text("현재 단계에 맞는 항목으로 저장됩니다.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(recipient.nickname)의 기록")
                .font(.title2)
                .fontWeight(.bold)

            Text("상황, 행동, 대응을 나누어 차근차근 남겨요.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= stepIndex ? AICOTheme.primaryOrange : Color.secondary.opacity(0.18))
                        .frame(height: 6)
                }
            }

            Text(steps[stepIndex].progressLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AICOTheme.primaryOrange)
        }
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch steps[stepIndex] {
        case .antecedent:
            CategorySelectionStepView(
                stage: .antecedent,
                title: "[A단계] 어떤 상황이었나요?",
                helperText: "행동이 나타나기 전의 장소, 활동, 주변 환경을 선택해요.",
                categories: categories(for: .antecedent),
                selectedNames: $selectedAntecedents,
                onAddCategory: { categoryInputStage = .antecedent }
            )
        case .behavior:
            CategorySelectionStepView(
                stage: .behavior,
                title: "[B단계] 어떤 행동이 있었나요?",
                helperText: "관찰된 행동이나 신호를 있는 그대로 선택해요.",
                categories: categories(for: .behavior),
                selectedNames: $selectedBehaviors,
                onAddCategory: { categoryInputStage = .behavior }
            )
        case .consequence:
            CategorySelectionStepView(
                stage: .consequence,
                title: "[C단계] 어떻게 대응했고 결과는 어땠나요?",
                helperText: "보호자의 대응과 이후 변화를 함께 선택해요.",
                categories: categories(for: .consequence),
                selectedNames: $selectedConsequences,
                onAddCategory: { categoryInputStage = .consequence }
            )
        case .note:
            finalInputStep
        }
    }

    private var finalInputStep: some View {
        VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("추가로 남길 내용이 있나요?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("자유롭게 메모를 남길 수 있어요. 사진/영상은 이번 단계에서는 자리만 확인합니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            TextField("예: 5분 정도 기다린 뒤 좋아하는 장난감을 보여주자 안정되었어요.", text: $note, axis: .vertical)
                .lineLimit(6...10)
                .padding()
                .background(AICOTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))

            Button {
                includeAttachmentPlaceholder.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: includeAttachmentPlaceholder ? "checkmark.circle.fill" : "photo.on.rectangle")
                        .foregroundStyle(AICOTheme.primaryOrange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("사진/영상 첨부 placeholder")
                            .font(.headline)

                        Text("실제 미디어 업로드는 구현하지 않아요.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(AICOTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                stepIndex = max(stepIndex - 1, 0)
            } label: {
                Text("이전")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(stepIndex == 0)

            Button {
                if stepIndex == steps.count - 1 {
                    saveRecord()
                } else {
                    stepIndex += 1
                }
            } label: {
                Text(stepIndex == steps.count - 1 ? "저장하기" : "다음")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AICOTheme.primaryOrange)
        }
    }

    private var categoryInputBinding: Binding<Bool> {
        Binding(
            get: { categoryInputStage != nil },
            set: { isPresented in
                if !isPresented {
                    categoryInputStage = nil
                    newCategoryName = ""
                }
            }
        )
    }

    private func categories(for stage: RecordCategoryStage) -> [RecordCategory] {
        categories
            .filter { $0.stage == stage }
            .sorted {
                if $0.isCustom != $1.isCustom {
                    return !$0.isCustom
                }
                return $0.createdAt < $1.createdAt
            }
    }

    private func saveCustomCategory() {
        guard let categoryInputStage else { return }

        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            self.categoryInputStage = nil
            newCategoryName = ""
            return
        }

        let category = RecordCategory(
            stage: categoryInputStage,
            name: trimmedName,
            isCustom: true
        )
        modelContext.insert(category)
        try? modelContext.save()
        select(trimmedName, for: categoryInputStage)

        self.categoryInputStage = nil
        newCategoryName = ""
    }

    private func select(_ name: String, for stage: RecordCategoryStage) {
        switch stage {
        case .antecedent:
            selectedAntecedents.insert(name)
        case .behavior:
            selectedBehaviors.insert(name)
        case .consequence:
            selectedConsequences.insert(name)
        }
    }

    private func saveRecord() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = RecordEntry(
            recipientId: recipient.id,
            antecedentCategories: Array(selectedAntecedents).sorted(),
            behaviorCategories: Array(selectedBehaviors).sorted(),
            consequenceCategories: Array(selectedConsequences).sorted(),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            attachmentNames: includeAttachmentPlaceholder ? ["prototype-attachment-placeholder"] : []
        )

        modelContext.insert(record)
        try? modelContext.save()
        savedRecord = record
    }

    private func resetFlow() {
        stepIndex = 0
        selectedAntecedents = []
        selectedBehaviors = []
        selectedConsequences = []
        note = ""
        includeAttachmentPlaceholder = false
        savedRecord = nil
    }
}

private enum RecordingStep: CaseIterable {
    case antecedent
    case behavior
    case consequence
    case note

    var progressLabel: String {
        switch self {
        case .antecedent:
            "[A단계]"
        case .behavior:
            "[B단계]"
        case .consequence:
            "[C단계]"
        case .note:
            "마무리"
        }
    }
}
