import SwiftData
import SwiftUI

struct RecipientRegistrationView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var nickname = ""
    @State private var ageText = ""
    @State private var gender = "기타 / 선택 안 함"
    @State private var autismTraits = ""
    @State private var validationMessage: String?

    private let genderOptions = ["남아", "여아", "기타 / 선택 안 함"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AICOTheme.sectionSpacing) {
                header
                requiredNameField
                optionalFields
                profileImagePlaceholder
                saveButton
            }
            .padding(AICOTheme.screenPadding)
        }
        .background(AICOTheme.softBackground)
        .navigationTitle("대상자 등록")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기록을 시작하기 전에")
                .font(.title2)
                .fontWeight(.bold)

            Text("기록이 누구의 순간인지 구분할 수 있도록 이름이나 별명을 먼저 등록해요. 나머지 정보는 선택 사항입니다.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var requiredNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이름 / 닉네임")
                .font(.headline)

            TextField("예: 민준이, 하늘이", text: $nickname)
                .textFieldStyle(.roundedBorder)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var optionalFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("나이")
                    .font(.headline)

                TextField("선택 사항", text: $ageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("성별")
                    .font(.headline)

                Picker("성별", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("자폐 정도 또는 특성")
                    .font(.headline)

                TextField(
                    "예: 소리에 민감함, 언어 표현이 적음, 전환 상황을 어려워함",
                    text: $autismTraits,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var profileImagePlaceholder: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18)
                .fill(AICOTheme.softOrangeBackground)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundStyle(AICOTheme.primaryOrange)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("프로필 이미지")
                    .font(.headline)

                Text("Phase 3에서는 실제 사진 업로드 없이 자리만 확인합니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
    }

    private var saveButton: some View {
        Button {
            saveRecipient()
        } label: {
            Text("등록하고 기록 시작하기")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AICOTheme.primaryOrange)
    }

    private func saveRecipient() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            validationMessage = "이름 또는 닉네임을 입력해주세요."
            return
        }

        let age = Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
        let normalizedGender = gender == "기타 / 선택 안 함" ? nil : gender
        let trimmedTraits = autismTraits.trimmingCharacters(in: .whitespacesAndNewlines)

        let recipient = RecipientProfile(
            nickname: trimmedNickname,
            age: age,
            gender: normalizedGender,
            autismTraits: trimmedTraits.isEmpty ? nil : trimmedTraits,
            profileImageName: nil
        )

        modelContext.insert(recipient)
        try? modelContext.save()
        validationMessage = nil
    }
}

#Preview {
    NavigationStack {
        RecipientRegistrationView()
    }
}
