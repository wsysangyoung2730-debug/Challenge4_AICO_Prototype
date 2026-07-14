import PhotosUI
import SwiftData
import SwiftUI

struct ABCRecordingFlowView: View {
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
    @State private var savedRecord: RecordEntry?
    @State private var validationMessage: String?
    @State private var recipientSwitchMessage: String?
    @State private var showsRecipientSelector = false
    @State private var showsDatePicker = false
    @State private var showsExitAlert = false
    @State private var showsRecipientSwitchAlert = false
    @State private var didLoadPrefilledAttachment = false
    @State private var hasSharedPhotoAttachment = false

    private let steps = RecordingStep.allCases

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
        Group {
            if savedRecord != nil {
                RecordingCompletionView(
                    onReturnHome: { dismiss() }
                )
            } else {
                ZStack {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 28) {
                            progressBar
                            recordControls
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 28)

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
            }
        }
        .background(AICOTheme.softBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(savedRecord == nil)
        .onChange(of: selectedAttachmentItem) {
            Task { await saveSelectedAttachment() }
        }
        .task {
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
        .alert("대상자를 변경할까요?", isPresented: $showsRecipientSwitchAlert) {
            Button("계속 작성하기", role: .cancel) {}
            Button("변경하기", role: .destructive) {
                clearDraftForRecipientSwitch()
                showsRecipientSelector = true
            }
        } message: {
            Text("대상자를 바꾸면 현재 작성 중인 기록 내용이 모두 사라집니다.")
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

    private var recordControls: some View {
        HStack(spacing: 12) {
            dateSelector
            profileSwitcher
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
        HStack(spacing: 10) {
            Text(selectedDate.formatted(.dateTime.year().month().day()))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 4)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
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
            HStack(spacing: 10) {
                recipientAvatar

                Text(currentRecipient.nickname)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 4)

                Image(systemName: recipients.count > 1 ? "chevron.down" : "person.crop.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 68)
            .background(AICOTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
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
        HStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                progressNode(for: index)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < stepIndex ? AICOTheme.primaryOrange : AICOTheme.primaryOrange.opacity(0.14))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
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
                .font(.system(size: 31))
                .foregroundStyle(isActive ? AICOTheme.primaryOrange : AICOTheme.primaryOrange.opacity(0.14))
                .frame(width: 32, height: 32)
        } else {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(isActive ? AICOTheme.primaryOrange : AICOTheme.primaryOrange.opacity(0.22))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch steps[stepIndex] {
        case .antecedent:
            CategorySelectionStepView(
                stage: .antecedent,
                title: "[A] 선행 상황",
                helperText: "행동이 일어나기 직전 무슨 일이 있었나요?",
                categories: categories(for: .antecedent),
                selectedNames: $selectedAntecedents,
                onAddCategory: { categoryInputStage = .antecedent }
            )
        case .behavior:
            CategorySelectionStepView(
                stage: .behavior,
                title: "[B] 행동 관찰",
                helperText: "어떤 행동을 보였나요?",
                categories: categories(for: .behavior),
                selectedNames: $selectedBehaviors,
                onAddCategory: { categoryInputStage = .behavior }
            )
        case .consequence:
            CategorySelectionStepView(
                stage: .consequence,
                title: "[C] 대응 및 결과",
                helperText: "행동 이후 무슨 일이 있었나요?",
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
                    .foregroundStyle(AICOTheme.textGray)
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
                            .foregroundStyle(AICOTheme.textGray)
                    }

                    Spacer()
                }
                .padding()
                .background(AICOTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
            }
            .buttonStyle(.plain)

            if !attachmentNames.isEmpty {
                if hasSharedPhotoAttachment {
                    Label("공유한 사진이 첨부되었어요.", systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(AICOTheme.primaryOrange)
                }

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
            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 8) {
                Button {
                    showsExitAlert = true
                } label: {
                    Image(systemName: "house")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(AICOTheme.cardBackground)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.8), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button {
                    validationMessage = nil
                    stepIndex = max(stepIndex - 1, 0)
                } label: {
                    Text("이전으로")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(stepIndex == 0 ? Color.secondary : AICOTheme.primaryOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(stepIndex == 0 ? Color.white.opacity(0.55) : AICOTheme.primaryOrange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(stepIndex == 0)

                Button {
                    moveForward()
                } label: {
                    Text(stepIndex == steps.count - 1 ? "저장하기" : "다음으로")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AICOTheme.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
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

    private var canChangeDate: Bool {
        steps[stepIndex] == .antecedent && savedRecord == nil
    }

    private var canSwitchRecipient: Bool {
        steps[stepIndex] == .antecedent && savedRecord == nil
    }

    private var hasDraftContent: Bool {
        !selectedAntecedents.isEmpty
            || !selectedBehaviors.isEmpty
            || !selectedConsequences.isEmpty
            || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !attachmentNames.isEmpty
    }

    private func handleRecipientSwitcherTap() {
        guard canSwitchRecipient else {
            recipientSwitchMessage = "대상자 변경은 A단계에서만 가능해요."
            return
        }

        if hasDraftContent {
            showsRecipientSwitchAlert = true
        } else {
            showsRecipientSelector = true
        }
    }

    private func selectRecipient(_ recipient: RecipientProfile) {
        guard recipient.id != currentRecipientID else { return }
        currentRecipientID = recipient.id
        clearDraftForRecipientSwitch()
    }

    private func clearDraftForRecipientSwitch() {
        attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        resetFlow()
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
            createdAt: selectedDate,
            antecedentCategories: Array(selectedAntecedents).sorted(),
            behaviorCategories: Array(selectedBehaviors).sorted(),
            consequenceCategories: Array(selectedConsequences).sorted(),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            attachmentNames: attachmentNames
        )

        modelContext.insert(record)
        try? modelContext.save()
        updateWidgetSnapshot(with: record)
        savedRecord = record
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
        savedRecord = nil
    }

    private func discardDraftAndDismiss() {
        attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        resetFlow()
        dismiss()
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
