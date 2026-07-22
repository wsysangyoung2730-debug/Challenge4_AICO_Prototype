import PhotosUI
import SwiftData
import SwiftUI

struct ABCRecordingFlowView: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]

    let recipients: [RecipientProfile]
    let prefilledAttachmentID: String?

    @State private var currentRecipientID: UUID
    @State private var selectedDate = Date()
    @State private var stepIndex = 0
    @State private var selectedAntecedents: Set<String> = []
    @State private var selectedBehaviors: Set<String> = []
    @State private var selectedConsequences: Set<String> = []
    @State private var note = ""
    @State private var selectedAttachmentItem: PhotosPickerItem?
    @State private var attachmentNames: [String] = []
    @State private var categoryInputStage: RecordCategoryStage?
    @State private var newCategoryName = ""
    @State private var showsCompletionAlert = false
    @State private var validationMessage: String?
    @State private var showsRecipientSelector = false
    @State private var showsDatePicker = false
    @State private var showsExitAlert = false
    @State private var didLoadPrefilledAttachment = false
    @State private var hasSharedPhotoAttachment = false

    private let steps = RecordingStep.allCases
    private let consequenceResponseNames = ["음식/음료 제공", "휴식 제공", "공간 이동", "안아줌", "거리둠", "그림/시각자료", "활동 전환"]

    init(
        recipients: [RecipientProfile],
        initialRecipient: RecipientProfile,
        prefilledAttachmentID: String? = nil
    ) {
        self.recipients = recipients
        self.prefilledAttachmentID = prefilledAttachmentID
        _currentRecipientID = State(initialValue: initialRecipient.id)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 28) {
                    recordControls
                    progressBar
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 13)

                ScrollView {
                    currentStepContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }

                bottomActionArea
            }

            if showsRecipientSelector {
                recipientSelectorOverlay
            }
        }
        .background(AICOTheme.softBackground)
        .tint(AICOTheme.primaryOrange)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onChange(of: selectedAttachmentItem) {
            Task { await saveSelectedAttachment() }
        }
        .task {
            sessionState.selectedRecipientID = currentRecipientID
            loadPrefilledAttachmentIfNeeded()
        }
        .sheet(isPresented: $showsDatePicker) {
            datePickerSheet
        }
        .alert("기록을 중단할까요?", isPresented: $showsExitAlert) {
            Button("계속 작성하기", role: .cancel) {}
            Button("나가기", role: .destructive) {
                discardDraftAndDismiss()
            }
        } message: {
            Text("지금 나가면 작성 중인 기록이 모두 삭제됩니다.")
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
        .alert("기록이 저장되었어요", isPresented: $showsCompletionAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("저장된 기록은 기록 보관함에서 확인할 수 있어요.")
        }
    }

    private var currentRecipient: RecipientProfile {
        recipients.first { $0.id == currentRecipientID } ?? recipients[0]
    }

    private var recordControls: some View {
        HStack(spacing: 8) {
            Button {
                validationMessage = nil

                if stepIndex > 0 {
                    stepIndex -= 1
                } else {
                    discardDraftAndDismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(AICOTheme.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            MainHeaderActions(
                recipients: recipients,
                showsCalendar: true,
                onCalendarTap: canChangeDate ? { showsDatePicker = true } : nil,
                onProfileTap: handleRecipientSwitcherTap
            )
        }
    }

    private var dateSelector: some View {
        Group {
            if canChangeDate {
                Button {
                    showsDatePicker = true
                } label: {
                    dateSelectorContent(showsChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                dateSelectorContent(showsChevron: false)
            }
        }
    }

    private func dateSelectorContent(showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text(selectedDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ko_KR"))))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(AICOTheme.cardBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.04), radius: 6)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("기록 날짜", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("날짜 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            showsDatePicker = false
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }

    private var profileSwitcher: some View {
        Button {
            handleRecipientSwitcherTap()
        } label: {
            HStack(spacing: 6) {
                Text(currentRecipient.nickname)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Image(systemName: recipients.count > 1 ? "chevron.down" : "person.crop.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(AICOTheme.cardBackground)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 6)
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
                        selectRecipient(recipient)
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
                                        .foregroundStyle(AICOTheme.textGray)
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
            .padding(.top, 8)
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
        .frame(width: 40, height: 40)
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
        HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { index in
                progressNode(for: index)
            }
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private func progressNode(for index: Int) -> some View {
        let isActive = index <= stepIndex
        let label = steps[index].progressLabel

        if label.isEmpty {
            Image(systemName: "seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(isActive ? AICOTheme.primaryOrange : Color(red: 0.918, green: 0.918, blue: 0.918))
                .frame(width: 30, height: 30)
        } else {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? .white : AICOTheme.textGray)
                .frame(width: 30, height: 30)
                .background(isActive ? AICOTheme.primaryOrange : Color(red: 0.918, green: 0.918, blue: 0.918))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch steps[stepIndex] {
        case .antecedent:
            CategorySelectionStepView(
                stage: .antecedent,
                title: "A. 선행 상황",
                helperText: "행동 이전 어떤 일이 있었나요?",
                categories: categories(for: .antecedent),
                selectedNames: $selectedAntecedents,
                onAddCategory: { categoryInputStage = .antecedent }
            )
        case .behavior:
            CategorySelectionStepView(
                stage: .behavior,
                title: "B. 행동 관찰",
                helperText: "어떤 행동을 관찰할 수 있었나요?",
                categories: categories(for: .behavior),
                selectedNames: $selectedBehaviors,
                onAddCategory: { categoryInputStage = .behavior }
            )
        case .consequence:
            CategorySelectionStepView(
                stage: .consequence,
                title: "C. 대응/결과",
                helperText: "행동 이후 어떤 일이 있었나요?",
                categories: categories(for: .consequence),
                selectedNames: $selectedConsequences,
                onAddCategory: { categoryInputStage = .consequence }
            )
        case .note:
            finalInputStep
        }
    }

    private var finalInputStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("최종 기록")
                    .font(.system(size: 24, weight: .semibold))

                Text("사진/영상으로 기록을 보강해보세요")
                    .font(.body)
                    .foregroundStyle(AICOTheme.textGray)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("사진/영상 등록")
                    .font(.system(size: 18, weight: .semibold))

                if let fileName = attachmentNames.last,
                   let image = ImageStorageService.image(for: fileName) {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                        Color.black.opacity(0.5)

                        Button {
                            removeAttachments()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("첨부 사진 삭제")
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 0.855, green: 0.855, blue: 0.855), lineWidth: 1)
                    }
                } else {
                    PhotosPicker(selection: $selectedAttachmentItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.855, green: 0.855, blue: 0.855), lineWidth: 1)

                            Image(systemName: "camera")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(AICOTheme.textGray)
                                .frame(width: 48, height: 48)
                        }
                        .frame(height: 200)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("추가 기록")
                    .font(.system(size: 18, weight: .semibold))

                TextField("시간, 환경, 발언 내용, 현장에 있었던 사람 등", text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.body)
                    .padding(16)
                    .background(Color(red: 0.918, green: 0.918, blue: 0.918))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }

            if hasSharedPhotoAttachment {
                Label("공유한 사진이 첨부되었어요.", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(AICOTheme.primaryOrange)
            }
        }
    }

    private var bottomActionArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 24)
            }

            Button {
                moveForward()
            } label: {
                Text(stepIndex == steps.count - 1 ? "저장하기" : "다음으로")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AICOTheme.primaryOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(AICOTheme.softBackground)
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

    private var canChangeDate: Bool {
        true
    }

    private func handleRecipientSwitcherTap() {
        showsRecipientSelector = true
    }

    private func selectRecipient(_ recipient: RecipientProfile) {
        guard recipient.id != currentRecipientID else { return }
        currentRecipientID = recipient.id
        sessionState.selectRecipient(recipient)
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

        if steps[stepIndex] == .consequence, !hasRequiredConsequenceSelections {
            validationMessage = "보호자 대응과 대응 결과를 각각 하나 이상 선택해주세요."
            return
        }

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

    private var hasRequiredConsequenceSelections: Bool {
        let consequenceCategories = categories(for: .consequence)
        let responseNames = Set(
            consequenceCategories
                .filter { consequenceResponseNames.contains($0.name) || $0.isCustom }
                .map(\.name)
        )
        let resultNames = Set(
            consequenceCategories
                .filter { !consequenceResponseNames.contains($0.name) && !$0.isCustom }
                .map(\.name)
        )

        return !selectedConsequences.isDisjoint(with: responseNames)
            && !selectedConsequences.isDisjoint(with: resultNames)
    }

    private func saveRecord() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = RecordEntry(
            recipientId: currentRecipient.id,
            createdAt: Date(),
            recordDate: selectedDate,
            antecedentCategories: Array(selectedAntecedents).sorted(),
            behaviorCategories: Array(selectedBehaviors).sorted(),
            consequenceCategories: Array(selectedConsequences).sorted(),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            attachmentNames: attachmentNames
        )

        modelContext.insert(record)
        try? modelContext.save()
        updateWidgetSnapshot(with: record)
        showsCompletionAlert = true
    }

    private func updateWidgetSnapshot(with newRecord: RecordEntry) {
        let snapshot = WidgetSnapshotBuilder.build(
            recipients: recipients,
            records: records + [newRecord],
            preferredRecipientId: currentRecipient.id
        )
        WidgetSnapshotStore.save(snapshot)
    }

    private func resetFlow() {
        stepIndex = 0
        selectedAntecedents = []
        selectedBehaviors = []
        selectedConsequences = []
        note = ""
        selectedAttachmentItem = nil
        attachmentNames = []
        hasSharedPhotoAttachment = false
        validationMessage = nil
        showsCompletionAlert = false
    }

    private func discardDraftAndDismiss() {
        attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        resetFlow()
        dismiss()
    }

    private func removeAttachments() {
        attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        attachmentNames = []
        selectedAttachmentItem = nil
        hasSharedPhotoAttachment = false
    }

    private func loadPrefilledAttachmentIfNeeded() {
        guard !didLoadPrefilledAttachment else { return }
        didLoadPrefilledAttachment = true

        guard let prefilledAttachmentID,
              let data = SharedPhotoAttachmentStore.imageData(for: prefilledAttachmentID),
              let fileName = try? ImageStorageService.saveImageData(data, prefix: "record")
        else {
            return
        }

        if !attachmentNames.contains(fileName) {
            attachmentNames.append(fileName)
        }
        hasSharedPhotoAttachment = true
        SharedPhotoAttachmentStore.deleteAttachment(id: prefilledAttachmentID)
    }

    @MainActor
    private func saveSelectedAttachment() async {
        guard let selectedAttachmentItem else { return }
        guard let data = try? await selectedAttachmentItem.loadTransferable(type: Data.self) else { return }
        if let fileName = try? ImageStorageService.saveImageData(data, prefix: "record") {
            removeAttachments()
            attachmentNames = [fileName]
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
            "A"
        case .behavior:
            "B"
        case .consequence:
            "C"
        case .note:
            ""
        }
    }
}
