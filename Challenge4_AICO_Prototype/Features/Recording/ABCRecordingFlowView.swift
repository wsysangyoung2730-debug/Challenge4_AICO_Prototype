import PhotosUI
import SwiftData
import SwiftUI

struct ABCRecordingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    let recipients: [RecipientProfile]

    @State private var currentRecipientID: UUID
    @State private var stepIndex = 0
    @State private var selectedAntecedents: Set<String> = []
    @State private var selectedBehaviors: Set<String> = []
    @State private var selectedConsequences: Set<String> = []
    @State private var note = ""
    @State private var selectedAttachmentItem: PhotosPickerItem?
    @State private var attachmentNames: [String] = []
    @State private var categoryInputStage: RecordCategoryStage?
    @State private var newCategoryName = ""
    @State private var savedRecord: RecordEntry?
    @State private var validationMessage: String?
    @State private var recipientSwitchMessage: String?
    @State private var showsRecipientSelector = false
    @State private var showsExitAlert = false

    private let steps = RecordingStep.allCases

    init(recipients: [RecipientProfile], initialRecipient: RecipientProfile) {
        self.recipients = recipients
        _currentRecipientID = State(initialValue: initialRecipient.id)
    }

    var body: some View {
        Group {
            if savedRecord != nil {
                RecordingCompletionView(
                    onReturnHome: { dismiss() }
                )
            } else {
                ZStack {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            profileSwitcher
                            progressBar
                        }
                        .padding(AICOTheme.screenPadding)

                        ScrollView {
                            currentStepContent
                                .padding(.horizontal, AICOTheme.screenPadding)
                                .padding(.bottom, 16)
                        }

                        bottomActionArea
                    }

                    if showsRecipientSelector {
                        recipientSelectorOverlay
                    }
                }
            }
        }
        .background(AICOTheme.softBackground)
        .navigationTitle("기록하기")
        .navigationBarTitleDisplayMode(.automatic)
        .navigationBarBackButtonHidden(savedRecord == nil)
        .toolbar {
            if savedRecord == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showsExitAlert = true
                    } label: {
                        Label("뒤로", systemImage: "chevron.left")
                    }
                }
            }
        }
        .onChange(of: selectedAttachmentItem) {
            Task { await saveSelectedAttachment() }
        }
        .alert("기록을 중단할까요?", isPresented: $showsExitAlert) {
            Button("계속 작성하기", role: .cancel) {}
            Button("나가기", role: .destructive) {
                discardDraftAndDismiss()
            }
        } message: {
            Text("지금 나가면 작성 중인 기록이 모두 삭제됩니다.")
        }
        .alert("대상자 전환", isPresented: recipientSwitchMessageBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(recipientSwitchMessage ?? "")
        }
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

    private var currentRecipient: RecipientProfile {
        recipients.first { $0.id == currentRecipientID } ?? recipients[0]
    }

    private var profileSwitcher: some View {
        Button {
            showsRecipientSelector = true
        } label: {
            HStack(spacing: 12) {
                recipientAvatar

                VStack(alignment: .leading, spacing: 2) {
                    Text("기록 대상")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(currentRecipient.nickname)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: recipients.count > 1 ? "chevron.down.circle.fill" : "person.crop.circle")
                    .foregroundStyle(AICOTheme.primaryOrange)
            }
            .padding(12)
            .background(AICOTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                    .stroke(AICOTheme.primaryOrange.opacity(0.18), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var recipientSelectorOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture {
                    showsRecipientSelector = false
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("기록 대상을 선택해요")
                    .font(.headline)

                ForEach(recipients) { recipient in
                    Button {
                        currentRecipientID = recipient.id
                        showsRecipientSelector = false
                    } label: {
                        HStack(spacing: 12) {
                            recipientAvatar(for: recipient)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(recipient.nickname)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if recipient.id == currentRecipientID {
                                    Text("현재 선택됨")
                                        .font(.caption)
                                        .foregroundStyle(AICOTheme.primaryOrange)
                                } else {
                                    Text("이 대상자로 기록하기")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if recipient.id == currentRecipientID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AICOTheme.primaryOrange)
                            }
                        }
                        .padding(10)
                        .background(recipient.id == currentRecipientID ? AICOTheme.softOrangeBackground : AICOTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                                .stroke(recipient.id == currentRecipientID ? AICOTheme.primaryOrange.opacity(0.45) : Color.clear, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(AICOTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, AICOTheme.screenPadding)
            .padding(.top, 18)
        }
    }

    private var recipientAvatar: some View {
        Group {
            if let image = ImageStorageService.image(for: currentRecipient.profileImageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AICOTheme.softOrangeBackground)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private func recipientAvatar(for recipient: RecipientProfile) -> some View {
        Group {
            if let image = ImageStorageService.image(for: recipient.profileImageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AICOTheme.softOrangeBackground)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
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
        .contentShape(Rectangle())
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

                Text("자유롭게 메모를 남기고 필요한 사진을 첨부할 수 있어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            TextField("예: 5분 정도 기다린 뒤 좋아하는 장난감을 보여주자 안정되었어요.", text: $note, axis: .vertical)
                .lineLimit(6...10)
                .padding()
                .background(AICOTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))

            PhotosPicker(selection: $selectedAttachmentItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundStyle(AICOTheme.primaryOrange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("사진 첨부")
                            .font(.headline)

                        Text("선택한 이미지는 앱 내부 로컬 저장소에만 보관됩니다.")
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

            if !attachmentNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(attachmentNames, id: \.self) { fileName in
                            if let image = ImageStorageService.image(for: fileName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                            }
                        }
                    }
                }
            }
        }
    }

    private var bottomActionArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(validationMessage ?? bottomHelperText)
                .font(.footnote)
                .fontWeight(validationMessage == nil ? .regular : .semibold)
                .foregroundStyle(validationMessage == nil ? Color.secondary : Color.red)

            HStack(spacing: 12) {
                Button {
                    validationMessage = nil
                    stepIndex = max(stepIndex - 1, 0)
                } label: {
                    Text("이전")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AICOTheme.softOrangeBackground.opacity(stepIndex == 0 ? 0.45 : 1))
                        .foregroundStyle(stepIndex == 0 ? .secondary : AICOTheme.primaryOrange)
                        .overlay {
                            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                                .stroke(AICOTheme.primaryOrange.opacity(stepIndex == 0 ? 0.12 : 0.35), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                }
                .buttonStyle(.plain)
                .disabled(stepIndex == 0)

                Button {
                    moveForward()
                } label: {
                    Text(stepIndex == steps.count - 1 ? "저장하기" : "다음")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AICOTheme.primaryOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AICOTheme.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.regularMaterial)
    }

    private var bottomHelperText: String {
        switch steps[stepIndex] {
        case .antecedent, .behavior, .consequence:
            "여러 항목을 선택할 수 있어요"
        case .note:
            "메모와 사진은 선택 사항이에요"
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

    private var recipientSwitchMessageBinding: Binding<Bool> {
        Binding(
            get: { recipientSwitchMessage != nil },
            set: { isPresented in
                if !isPresented {
                    recipientSwitchMessage = nil
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

        let category = RecordCategory(stage: categoryInputStage, name: trimmedName, isCustom: true)
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

    private func moveForward() {
        validationMessage = nil

        guard steps[stepIndex] == .note || hasSelectionForCurrentStep else {
            validationMessage = "하나 이상의 항목을 선택해주세요."
            return
        }

        if stepIndex == steps.count - 1 {
            saveRecord()
        } else {
            stepIndex += 1
        }
    }

    private var hasSelectionForCurrentStep: Bool {
        switch steps[stepIndex] {
        case .antecedent:
            !selectedAntecedents.isEmpty
        case .behavior:
            !selectedBehaviors.isEmpty
        case .consequence:
            !selectedConsequences.isEmpty
        case .note:
            true
        }
    }

    private func saveRecord() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = RecordEntry(
            recipientId: currentRecipient.id,
            antecedentCategories: Array(selectedAntecedents).sorted(),
            behaviorCategories: Array(selectedBehaviors).sorted(),
            consequenceCategories: Array(selectedConsequences).sorted(),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            attachmentNames: attachmentNames
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
        selectedAttachmentItem = nil
        attachmentNames = []
        validationMessage = nil
        savedRecord = nil
    }

    private func discardDraftAndDismiss() {
        attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        resetFlow()
        dismiss()
    }

    @MainActor
    private func saveSelectedAttachment() async {
        guard let selectedAttachmentItem else { return }
        guard let data = try? await selectedAttachmentItem.loadTransferable(type: Data.self) else { return }
        if let fileName = try? ImageStorageService.saveImageData(data, prefix: "record") {
            attachmentNames.append(fileName)
        }
        self.selectedAttachmentItem = nil
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
