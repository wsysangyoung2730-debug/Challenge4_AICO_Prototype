import SwiftData
import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt) private var records: [RecordEntry]
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    @AppStorage("aico.notificationsEnabled") private var notificationsEnabled = false
    @State private var showsAppDataResetAlert = false
    @State private var pendingNotificationValue: Bool?

    var body: some View {
        ZStack {
            AICOTheme.softBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    settingsHeader
                    profileSection
                    managementSection
                    appSection
                    dataSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
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
            Text("대상자, 기록, 카테고리 등 로컬 프로토타입 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없어요.")
        }
    }

    private var selectedRecipient: RecipientProfile? {
        recipients.first { $0.id == sessionState.selectedRecipientID } ?? recipients.first
    }

    private var caregiverDisplayName: String {
        if let selectedRecipient {
            return "\(selectedRecipient.nickname)맘"
        }
        return "아이코 보호자"
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 28) {
            Button {
                dismiss()
            } label: {
                SettingsHeaderIcon(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Text("설정")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    private var profileSection: some View {
        SettingsCard {
            NavigationLink {
                RecipientManagementView()
            } label: {
                SettingsProfileRow(
                    title: caregiverDisplayName,
                    subtitle: "부모(모)",
                    imageName: selectedRecipient?.profileImageName
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PrototypePlaceholderView(
                    title: "새로운 기록 연동",
                    message: "연동 기능은 이후 보호자 공유와 동기화 단계에서 연결될 예정이에요."
                )
            } label: {
                SettingsNavigationRow(showIcon: false, showsDivider: false) {
                    HStack(spacing: 8) {
                        Text("새로운 기록 연동")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 8)

                        Text("1")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AICOTheme.primaryOrange)
                            .clipShape(Circle())
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var managementSection: some View {
        SettingsSection(title: "관리") {
            NavigationLink {
                RecipientManagementView()
            } label: {
                SettingsNavigationRow(title: "대상자 관리", systemImage: "face.smiling")
            }
            .buttonStyle(.plain)

            NavigationLink {
                CategoryManagementView()
            } label: {
                SettingsNavigationRow(title: "태그 관리", systemImage: "tag")
            }
            .buttonStyle(.plain)

            NavigationLink {
                PrototypePlaceholderView(
                    title: "보호자 연동 관리",
                    message: "실제 보호자 연동 기능은 CloudKit 공유 구현 단계에서 연결될 예정이에요."
                )
            } label: {
                SettingsNavigationRow(title: "보호자 연동 관리", systemImage: "person.2", showsDivider: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var appSection: some View {
        SettingsSection(title: "앱") {
            SettingsToggleRow(
                title: "알림 ON/OFF",
                systemImage: "bell",
                isOn: notificationToggleBinding
            )

            NavigationLink {
                PrototypePlaceholderView(
                    title: "아이코 사용 가이드",
                    message: "사용 가이드는 이후 온보딩과 도움말 콘텐츠가 정리되면 연결될 예정이에요."
                )
            } label: {
                SettingsNavigationRow(title: "아이코 사용 가이드", systemImage: "questionmark.circle", showsDivider: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터") {
            Button(role: .destructive) {
                showsAppDataResetAlert = true
            } label: {
                SettingsActionRow(title: "앱 데이터 전체 삭제", systemImage: "trash")
            }
            .buttonStyle(.plain)
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

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            SettingsCard {
                content
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 0)
    }
}

private struct SettingsProfileRow: View {
    let title: String
    let subtitle: String
    let imageName: String?

    var body: some View {
        HStack(spacing: 14) {
            RecipientAvatarView(fileName: imageName, size: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AICOTheme.textGray)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .overlay(alignment: .bottom) {
            SettingsDivider()
        }
    }
}

private struct SettingsNavigationRow<Content: View>: View {
    let showIcon: Bool
    let systemImage: String?
    let showsDivider: Bool
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String,
        showsDivider: Bool = true
    ) where Content == Text {
        self.showIcon = true
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.content = Text(title)
    }

    init(
        showIcon: Bool = false,
        systemImage: String? = nil,
        showsDivider: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.showIcon = showIcon
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            if showIcon, let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .frame(width: 22, height: 22)
            }

            content
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AICOTheme.textGray)
        }
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) {
            if showsDivider {
                SettingsDivider()
            }
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 22, height: 22)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AICOTheme.primaryOrange)
        }
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) {
            SettingsDivider()
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 22, height: 22)

            Text(title)
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(AICOTheme.primaryOrange)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.855, green: 0.855, blue: 0.855))
            .frame(height: 1)
    }
}

private struct PrototypePlaceholderView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .semibold))

            Text(message)
                .font(.body)
                .foregroundStyle(AICOTheme.textGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(AICOTheme.softBackground)
        .navigationTitle(title)
    }
}

private func settingsDetailHeader(
    title: String,
    subtitle: String? = nil,
    iconName: String,
    action: @escaping () -> Void
) -> some View {
    VStack(alignment: .leading, spacing: 28) {
        Button(action: action) {
            SettingsHeaderIcon(systemName: iconName)
        }
        .buttonStyle(.plain)

        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
            }
        }
    }
}

private struct SettingsHeaderIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(AICOTheme.cardBackground)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
            .contentShape(Circle())
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
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]
    @State private var showsResetAlert = false

    var body: some View {
        ZStack {
            AICOTheme.softBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    settingsDetailHeader(
                        title: "태그 관리",
                        subtitle: "대상자만을 위한 맞춤 태그를 관리해보세요",
                        iconName: "chevron.left",
                        action: { dismiss() }
                    )

                    ForEach(RecordCategoryStage.allCases, id: \.self) { stage in
                        categoryStageSection(stage)
                    }

                    SettingsCard {
                        Button(role: .destructive) {
                            showsResetAlert = true
                        } label: {
                            Text("태그 초기화")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AICOTheme.primaryOrange)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .alert("기록 카테고리를 초기화할까요?", isPresented: $showsResetAlert) {
            Button("취소", role: .cancel) {}
            Button("초기화", role: .destructive) {
                resetCategories()
            }
        } message: {
            Text("직접 추가하거나 수정한 카테고리가 기본값으로 되돌아갈 수 있어요.")
        }
    }

    private func categoryStageSection(_ stage: RecordCategoryStage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stage.settingsDisplayTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            SettingsCard {
                let stageCategories = categoriesForStage(stage)

                if stageCategories.isEmpty {
                    Text("아직 태그가 없어요. 기록 화면에 들어가면 기본 태그가 준비됩니다.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AICOTheme.textGray)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                } else {
                    ForEach(stageCategories) { category in
                        categoryRow(category)
                    }
                }

                NavigationLink {
                    CategoryEditView(mode: .add(stage))
                } label: {
                    Text("태그 추가")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AICOTheme.primaryOrange)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func categoryRow(_ category: RecordCategory) -> some View {
        if category.isCustom {
            NavigationLink {
                CategoryEditView(mode: .edit(category))
            } label: {
                categoryRowContent(category)
            }
            .buttonStyle(.plain)
        } else {
            categoryRowContent(category)
        }
    }

    private func categoryRowContent(_ category: RecordCategory) -> some View {
        HStack(spacing: 8) {
            Text(category.name)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(category.isCustom ? "추가됨" : "기본")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)

            if !category.isCustom {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AICOTheme.textGray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .overlay(alignment: .bottom) {
            SettingsDivider()
        }
    }

    private func categoriesForStage(_ stage: RecordCategoryStage) -> [RecordCategory] {
        categories
            .filter { $0.stage == stage }
            .sorted {
                if $0.isCustom != $1.isCustom {
                    return !$0.isCustom
                }
                return $0.createdAt < $1.createdAt
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
    private let maxCategoryNameLength = 15

    init(mode: CategoryEditMode) {
        self.mode = mode
        _name = State(initialValue: mode.category?.name ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AICOTheme.softBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    settingsDetailHeader(
                        title: mode.title,
                        subtitle: "대상자만을 위한 맞춤 태그를 관리해보세요",
                        iconName: "xmark",
                        action: { dismiss() }
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(mode.stage.settingsDisplayTitle)
                            .font(.system(size: 18, weight: .semibold))

                        SettingsCard {
                            TextField("태그명", text: $name)
                                .font(.system(size: 18, weight: .medium))
                                .textInputAutocapitalization(.never)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        }

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        }
                    }

                    if mode.category?.isCustom == true {
                        SettingsCard {
                            Button(role: .destructive) {
                                showsDeleteConfirmation = true
                            } label: {
                                Text("태그 삭제")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(AICOTheme.primaryOrange)
                                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 112)
            }

            Button {
                save()
            } label: {
                Text(mode.category == nil ? "추가하기" : "저장하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canSave ? .white : AICOTheme.textGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canSave ? AICOTheme.primaryOrange : Color(red: 0.918, green: 0.918, blue: 0.918))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(AICOTheme.softBackground)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onChange(of: name) {
            limitCategoryNameLength()
        }
        .alert("카테고리를 삭제할까요?", isPresented: $showsDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제하기", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("기본 카테고리는 삭제할 수 없고, 커스텀 카테고리만 삭제됩니다.")
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    private func limitCategoryNameLength() {
        guard name.count > maxCategoryNameLength else { return }
        name = String(name.prefix(maxCategoryNameLength))
    }

    private func save() {
        guard !trimmedName.isEmpty else {
            validationMessage = "태그명을 입력해주세요."
            return
        }

        let normalizedName = String(trimmedName.prefix(maxCategoryNameLength))

        if let category = mode.category {
            guard category.isCustom else {
                validationMessage = "기본 태그는 수정하지 않습니다."
                return
            }
            category.name = normalizedName
        } else {
            modelContext.insert(
                RecordCategory(
                    stage: mode.stage,
                    name: normalizedName,
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

    var settingsDisplayTitle: String {
        switch self {
        case .antecedent: "A. 선행 상황"
        case .behavior: "B. 행동 관찰"
        case .consequence: "C. 보호자 대응"
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
