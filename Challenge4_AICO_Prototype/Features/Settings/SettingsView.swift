import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt) private var records: [RecordEntry]
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    @AppStorage("aico.notificationsEnabled") private var notificationsEnabled = false
    @State private var showsResetConfirmation = false

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
            }

            Section("알림 설정") {
                Toggle(isOn: $notificationsEnabled) {
                    SettingsRow(title: "알림 ON/OFF", systemImage: "bell.fill")
                }

                Text("프로토타입에서는 앱 내부 설정값만 저장됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("데이터") {
                Button(role: .destructive) {
                    showsResetConfirmation = true
                } label: {
                    SettingsRow(title: "앱 데이터 전체 삭제", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("설정")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
        .confirmationDialog(
            "로컬 프로토타입 데이터를 삭제할까요?",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제하기", role: .destructive) {
                resetLocalData()
            }

            Button("취소", role: .cancel) {}
        } message: {
            Text("대상자, 기록, 카테고리 데이터가 삭제됩니다. 서비스 소개 완료 상태는 유지하고 홈/기록 튜토리얼 상태는 다시 볼 수 있도록 초기화합니다.")
        }
    }

    private func resetLocalData() {
        records.forEach(modelContext.delete)
        recipients.forEach(modelContext.delete)
        categories.forEach(modelContext.delete)
        try? modelContext.save()

        sessionState.hasSeenHomeTutorial = false
        sessionState.hasSeenRecordingTutorial = false
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
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recipients) { recipient in
                        NavigationLink {
                            RecipientEditView(mode: .edit(recipient))
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(recipient.nickname)
                                    .font(.headline)

                                Text(detailText(for: recipient))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                if records.contains(where: { $0.recipientId == recipient.id }) {
                                    Text("연결된 기록이 있어 삭제 시 기록에는 '등록된 대상자'로 표시될 수 있어요.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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

    let mode: RecipientEditMode

    @State private var nickname: String
    @State private var ageText: String
    @State private var gender: String
    @State private var traits: String
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
    }

    var body: some View {
        Form {
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
        .confirmationDialog("대상자를 삭제할까요?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제하기", role: .destructive) {
                deleteRecipient()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("관련 기록은 삭제하지 않고 남겨둡니다.")
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

        if let recipient = mode.recipient {
            recipient.nickname = trimmedNickname
            recipient.age = Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
            recipient.gender = normalizedGender
            recipient.autismTraits = normalizedTraits.isEmpty ? nil : normalizedTraits
        } else {
            modelContext.insert(
                RecipientProfile(
                    nickname: trimmedNickname,
                    age: Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines)),
                    gender: normalizedGender,
                    autismTraits: normalizedTraits.isEmpty ? nil : normalizedTraits
                )
            )
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteRecipient() {
        guard let recipient = mode.recipient else { return }
        modelContext.delete(recipient)
        try? modelContext.save()
        dismiss()
    }
}

private struct CategoryManagementView: View {
    @Query(sort: \RecordCategory.createdAt) private var categories: [RecordCategory]

    var body: some View {
        List {
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
                            .foregroundStyle(.secondary)
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
    }

    private func categoryRow(_ category: RecordCategory) -> some View {
        HStack {
            Text(category.name)
            Spacer()
            Text(category.isCustom ? "커스텀" : "기본")
                .font(.caption)
                .foregroundStyle(category.isCustom ? AICOTheme.primaryOrange : .secondary)
        }
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
        .confirmationDialog("카테고리를 삭제할까요?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제하기", role: .destructive) {
                deleteCategory()
            }
            Button("취소", role: .cancel) {}
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
