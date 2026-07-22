import SwiftData
import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt) private var records: [RecordEntry]
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    @AppStorage("aico.notificationsEnabled") private var notificationsEnabled = false
    @State private var showsAppDataResetAlert = false
    @State private var pendingNotificationValue: Bool?

    var body: some View {
        List {
            Section("관리") {
                NavigationLink {
                    RecipientManagementView()
                } label: {
                    SettingsRow(title: "대상자 관리", systemImage: "person.crop.circle")
                }

                NavigationLink {
                    CategoryManagementView()
                } label: {
                    SettingsRow(title: "기록 카테고리 관리", systemImage: "tag.fill")
                }

                NavigationLink {
                    CaregiverSharingSettingsView()
                } label: {
                    SettingsRow(title: "보호자 공유 설정", systemImage: "person.2.fill")
                }
            }

            Section("알림 설정") {
                Toggle(isOn: notificationToggleBinding) {
                    SettingsRow(title: "알림 ON/OFF", systemImage: "bell.fill")
                }

                Text("프로토타입에서는 앱 내부 설정값만 저장됩니다.")
                    .font(.footnote)
                    .foregroundStyle(AICOTheme.textGray)
            }

            Section("데이터") {
                Button(role: .destructive) {
                    showsAppDataResetAlert = true
                } label: {
                    SettingsRow(title: "앱 데이터 전체 삭제", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("설정")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
        .alert(notificationAlertTitle, isPresented: notificationAlertBinding) {
            Button("취소", role: .cancel) {
                pendingNotificationValue = nil
            }
            Button("확인") {
                if let pendingNotificationValue {
                    notificationsEnabled = pendingNotificationValue
                }
                pendingNotificationValue = nil
            }
        } message: {
            Text(notificationAlertMessage)
        }
        .alert("앱 데이터를 모두 삭제할까요?", isPresented: $showsAppDataResetAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제하기", role: .destructive) {
                resetLocalData()
            }
        } message: {
            Text("대상자, 기록, 카테고리가 이 기기에서 삭제되고, 내가 공유한 기록은 상대 기기에서도 사라져요. 이 작업은 되돌릴 수 없어요.")
        }
    }

    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { pendingNotificationValue = $0 }
        )
    }

    private var notificationAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingNotificationValue != nil },
            set: { isPresented in
                if !isPresented {
                    pendingNotificationValue = nil
                }
            }
        )
    }

    private var notificationAlertTitle: String {
        pendingNotificationValue == true ? "알림을 켤까요?" : "알림을 끌까요?"
    }

    private var notificationAlertMessage: String {
        pendingNotificationValue == true
            ? "프로토타입에서는 앱 내부 설정값만 저장됩니다."
            : "기록 리마인드와 안내 알림을 받지 않도록 설정됩니다."
    }

    private func resetLocalData() {
        let myUploadedIDs = records.filter { !$0.isRemote }.map(\.id)
        Task { await GuardianSyncManager.deleteRecords(ids: myUploadedIDs) }

        records.flatMap(\.attachmentNames).forEach { ImageStorageService.deleteImage(named: $0) }
        recipients.map(\.profileImageName).forEach { ImageStorageService.deleteImage(named: $0) }
        records.forEach(modelContext.delete)
        recipients.forEach(modelContext.delete)
        categories.forEach(modelContext.delete)
        try? modelContext.save()

        sessionState.hasSeenHomeTutorial = false
        sessionState.hasSeenRecordingTutorial = false
        WidgetSnapshotStore.save(.fallback)
    }
}

private struct SettingsRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 24)

            Text(title)
        }
    }
}

private struct RecipientManagementView: View {
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt) private var records: [RecordEntry]

    var body: some View {
        List {
            Section {
                NavigationLink {
                    RecipientEditView(mode: .add)
                } label: {
                    Label("새 대상자 추가", systemImage: "plus.circle.fill")
                        .foregroundStyle(AICOTheme.primaryOrange)
                }
            }

            Section("등록된 대상자") {
                if recipients.isEmpty {
                    Text("등록된 대상자가 아직 없어요.")
                        .foregroundStyle(AICOTheme.textGray)
                } else {
                    ForEach(recipients) { recipient in
                        NavigationLink {
                            RecipientEditView(mode: .edit(recipient))
                        } label: {
                            HStack(spacing: 12) {
                                RecipientAvatarView(fileName: recipient.profileImageName, size: 44)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(recipient.nickname)
                                        .font(.headline)

                                    Text(detailText(for: recipient))
                                        .font(.subheadline)
                                        .foregroundStyle(AICOTheme.textGray)
                                        .lineLimit(2)

                                    if records.contains(where: { $0.recipientId == recipient.id }) {
                                        Text("연결된 기록이 있어 삭제 시 기록에는 '등록된 대상자'로 표시될 수 있어요.")
                                            .font(.caption)
                                            .foregroundStyle(AICOTheme.textGray)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("대상자 관리")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
    }

    private func detailText(for recipient: RecipientProfile) -> String {
        let ageText = recipient.age.map { "\($0)세" }
        let items = [ageText, recipient.gender, recipient.autismTraits]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        return items.isEmpty ? "선택 정보 없음" : items.joined(separator: " · ")
    }
}

private enum RecipientEditMode {
    case add
    case edit(RecipientProfile)

    var title: String {
        switch self {
        case .add: "대상자 추가"
        case .edit: "대상자 수정"
        }
    }

    var recipient: RecipientProfile? {
        if case let .edit(recipient) = self {
            return recipient
        }
        return nil
    }
}

private struct RecipientEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]

    let mode: RecipientEditMode

    @State private var nickname: String
    @State private var ageText: String
    @State private var gender: String
    @State private var traits: String
    @State private var profileImageName: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var validationMessage: String?
    @State private var showsDeleteConfirmation = false

    private let genderOptions = ["남아", "여아", "기타 / 선택 안 함"]

    init(mode: RecipientEditMode) {
        self.mode = mode
        let recipient = mode.recipient
        _nickname = State(initialValue: recipient?.nickname ?? "")
        _ageText = State(initialValue: recipient?.age.map(String.init) ?? "")
        _gender = State(initialValue: recipient?.gender ?? "기타 / 선택 안 함")
        _traits = State(initialValue: recipient?.autismTraits ?? "")
        _profileImageName = State(initialValue: recipient?.profileImageName)
    }

    var body: some View {
        Form {
            Section("프로필 이미지") {
                HStack(spacing: 14) {
                    RecipientAvatarView(fileName: profileImageName, size: 62)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text(profileImageName == nil ? "이미지 선택" : "이미지 변경")
                            .fontWeight(.semibold)
                            .foregroundStyle(AICOTheme.primaryOrange)
                    }
                }
            }

            Section("기본 정보") {
                TextField("이름 / 닉네임", text: $nickname)
                TextField("나이", text: $ageText)
                    .keyboardType(.numberPad)

                Picker("성별", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                TextField("특성 메모", text: $traits, axis: .vertical)
                    .lineLimit(3...5)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("저장하기") {
                    save()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AICOTheme.primaryOrange)
            }

            if mode.recipient != nil {
                Section {
                    Button("대상자 삭제", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                } footer: {
                    Text("삭제해도 기존 기록은 함께 삭제하지 않습니다. 기록 상세에서는 대상자명이 기본 문구로 표시될 수 있어요.")
                }
            }
        }
        .navigationTitle(mode.title)
        .onChange(of: selectedPhotoItem) {
            Task { await saveSelectedProfileImage() }
        }
        .onChange(of: ageText) {
            ageText = sanitizedAgeText(ageText)
        }
        .alert("대상자를 삭제할까요?", isPresented: $showsDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제하기", role: .destructive) {
                deleteRecipient()
            }
        } message: {
            Text("삭제 후에도 기존 기록은 남아 있을 수 있어요.")
        }
    }

    private func save() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            validationMessage = "이름 또는 닉네임을 입력해주세요."
            return
        }

        let normalizedGender = gender == "기타 / 선택 안 함" ? nil : gender
        let normalizedTraits = traits.trimmingCharacters(in: .whitespacesAndNewlines)

        let savedRecipient: RecipientProfile

        if let recipient = mode.recipient {
            recipient.nickname = trimmedNickname
            recipient.age = Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
            recipient.gender = normalizedGender
            recipient.autismTraits = normalizedTraits.isEmpty ? nil : normalizedTraits
            recipient.profileImageName = profileImageName
            savedRecipient = recipient
        } else {
            let recipient = RecipientProfile(
                nickname: trimmedNickname,
                age: Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines)),
                gender: normalizedGender,
                autismTraits: normalizedTraits.isEmpty ? nil : normalizedTraits,
                profileImageName: profileImageName
            )
            modelContext.insert(recipient)
            savedRecipient = recipient
        }

        try? modelContext.save()
        updateWidgetSnapshot(preferredRecipient: savedRecipient)
        dismiss()
    }

    private func sanitizedAgeText(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(2))
    }

    private func deleteRecipient() {
        guard let recipient = mode.recipient else { return }
        ImageStorageService.deleteImage(named: recipient.profileImageName)
        modelContext.delete(recipient)
        try? modelContext.save()
        updateWidgetSnapshot(excluding: recipient.id)
        dismiss()
    }

    private func updateWidgetSnapshot(preferredRecipient: RecipientProfile? = nil, excluding deletedRecipientId: UUID? = nil) {
        var activeRecipients = recipients.filter { $0.id != deletedRecipientId }
        if let preferredRecipient, !activeRecipients.contains(where: { $0.id == preferredRecipient.id }) {
            activeRecipients.append(preferredRecipient)
        }
        let snapshot = WidgetSnapshotBuilder.build(
            recipients: activeRecipients,
            records: records,
            preferredRecipientId: preferredRecipient?.id
        )
        WidgetSnapshotStore.save(snapshot)
    }

    @MainActor
    private func saveSelectedProfileImage() async {
        guard let selectedPhotoItem else { return }
        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else { return }
            ImageStorageService.deleteImage(named: profileImageName)
            profileImageName = try ImageStorageService.saveImageData(data, prefix: "recipient")
        } catch {
            validationMessage = "이미지를 불러오지 못했어요. 다시 선택해주세요."
        }
    }
}

private struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]
    @State private var showsResetAlert = false

    var body: some View {
        List {
            Section {
                Button("카테고리 초기화", role: .destructive) {
                    showsResetAlert = true
                }
            } footer: {
                Text("기본 카테고리를 다시 준비하고 직접 추가한 카테고리는 삭제합니다.")
            }

            ForEach(RecordCategoryStage.allCases, id: \.self) { stage in
                Section(stage.displayTitle) {
                    NavigationLink {
                        CategoryEditView(mode: .add(stage))
                    } label: {
                        Label("커스텀 카테고리 추가", systemImage: "plus.circle.fill")
                            .foregroundStyle(AICOTheme.primaryOrange)
                    }

                    let stageCategories = categories
                        .filter { $0.stage == stage }
                        .sorted {
                            if $0.isCustom != $1.isCustom {
                                return !$0.isCustom
                            }
                            return $0.name < $1.name
                        }

                    if stageCategories.isEmpty {
                        Text("아직 카테고리가 없어요. 기록 화면에 들어가면 기본 카테고리가 준비됩니다.")
                            .foregroundStyle(AICOTheme.textGray)
                    } else {
                        ForEach(stageCategories) { category in
                            if category.isCustom {
                                NavigationLink {
                                    CategoryEditView(mode: .edit(category))
                                } label: {
                                    categoryRow(category)
                                }
                            } else {
                                categoryRow(category)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("기록 카테고리")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
        .alert("기록 카테고리를 초기화할까요?", isPresented: $showsResetAlert) {
            Button("취소", role: .cancel) {}
            Button("초기화", role: .destructive) {
                resetCategories()
            }
        } message: {
            Text("직접 추가하거나 수정한 카테고리가 기본값으로 되돌아갈 수 있어요.")
        }
    }

    private func categoryRow(_ category: RecordCategory) -> some View {
        HStack {
            Text(category.name)
            Spacer()
            Text(category.isCustom ? "커스텀" : "기본")
                .font(.caption)
                .foregroundStyle(category.isCustom ? AICOTheme.primaryOrange : AICOTheme.textGray)
        }
    }

    private func resetCategories() {
        categories.forEach(modelContext.delete)

        for seed in DefaultRecordCategorySeed.all {
            modelContext.insert(
                RecordCategory(
                    stage: seed.stage,
                    name: seed.name,
                    isCustom: false
                )
            )
        }

        try? modelContext.save()
    }
}

private enum CategoryEditMode {
    case add(RecordCategoryStage)
    case edit(RecordCategory)

    var title: String {
        switch self {
        case .add: "카테고리 추가"
        case .edit: "카테고리 수정"
        }
    }

    var stage: RecordCategoryStage {
        switch self {
        case let .add(stage): stage
        case let .edit(category): category.stage
        }
    }

    var category: RecordCategory? {
        if case let .edit(category) = self {
            return category
        }
        return nil
    }
}

private struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: CategoryEditMode

    @State private var name: String
    @State private var validationMessage: String?
    @State private var showsDeleteConfirmation = false

    init(mode: CategoryEditMode) {
        self.mode = mode
        _name = State(initialValue: mode.category?.name ?? "")
    }

    var body: some View {
        Form {
            Section(mode.stage.displayTitle) {
                TextField("카테고리 이름", text: $name)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("저장하기") {
                    save()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AICOTheme.primaryOrange)
            }

            if mode.category?.isCustom == true {
                Section {
                    Button("커스텀 카테고리 삭제", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(mode.title)
        .alert("카테고리를 삭제할까요?", isPresented: $showsDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제하기", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("기본 카테고리는 삭제할 수 없고, 커스텀 카테고리만 삭제됩니다.")
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "카테고리 이름을 입력해주세요."
            return
        }

        if let category = mode.category {
            guard category.isCustom else {
                validationMessage = "기본 카테고리는 수정하지 않습니다."
                return
            }
            category.name = trimmedName
        } else {
            modelContext.insert(
                RecordCategory(
                    stage: mode.stage,
                    name: trimmedName,
                    isCustom: true
                )
            )
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteCategory() {
        guard let category = mode.category, category.isCustom else { return }
        modelContext.delete(category)
        try? modelContext.save()
        dismiss()
    }
}

private struct RecipientAvatarView: View {
    let fileName: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let image = ImageStorageService.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.62))
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AICOTheme.softOrangeBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private extension RecordCategoryStage {
    var displayTitle: String {
        switch self {
        case .antecedent: "[A단계] 상황"
        case .behavior: "[B단계] 행동"
        case .consequence: "[C단계] 대응/결과"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AnonymousSessionState())
    }
    .modelContainer(SwiftDataContainer.shared)
}
