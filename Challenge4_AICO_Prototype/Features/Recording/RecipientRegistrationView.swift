import PhotosUI
import SwiftData
import SwiftUI

struct RecipientRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionState: AnonymousSessionState

    @State private var nickname = ""
    @State private var ageText = ""
    @State private var gender = "남아"
    @State private var autismTraits = ""
    @State private var validationMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImageName: String?
    @State private var didSaveRecipient = false

    private let genderOptions = ["남아", "여아", "기타/미선택"]
    private let autismTraitOptions = ["경도", "중등도", "최중증"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                closeButton
                header
                profilePhotoField
                nameField
                demographicsField
                traitsField
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            registerButton
        }
        .background(AICOTheme.appBackground)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedPhotoItem) {
            Task { await saveSelectedProfileImage() }
        }
        .onChange(of: ageText) {
            ageText = sanitizedAgeText(ageText)
        }
        .onDisappear {
            if !didSaveRecipient {
                ImageStorageService.deleteImage(named: profileImageName)
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("기록하기에 앞서,\n대상자에 대해 알려주세요")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)

            Text("대상자 별 기록 관리, 명함 서비스를 이용할 수 있어요")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)
        }
    }

    private var profilePhotoField: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 12) {
                profileAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text("대상자 사진")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("얼굴 사진이 아니어도 돼요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AICOTheme.textGray)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(profileImageName == nil ? "대상자 사진 선택" : "대상자 사진 변경")
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let image = ImageStorageService.image(for: profileImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
        } else {
            Image(systemName: "camera")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)
                .frame(width: 50, height: 50)
                .overlay {
                    Circle()
                        .stroke(Color(.separator), lineWidth: 1)
                }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            requiredLabel

            TextField("예) 홍길동, 튼튼이", text: $nickname)
                .font(.system(size: 16, weight: .medium))
                .textInputAutocapitalization(.never)
                .padding(16)
                .background(AICOTheme.cardGray, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var requiredLabel: some View {
        HStack(spacing: 4) {
            Text("이름/닉네임")
                .foregroundStyle(.primary)
            Text("*")
                .foregroundStyle(AICOTheme.primaryOrange)
        }
        .font(.system(size: 18, weight: .semibold))
    }

    private var demographicsField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나이/성별")
                .font(.system(size: 18, weight: .semibold))

            HStack {
                TextField("예) 8", text: $ageText)
                    .keyboardType(.numberPad)

                Spacer()

                Text("세")
                    .foregroundStyle(.primary)
            }
            .font(.system(size: 16, weight: .medium))
            .padding(16)
            .background(AICOTheme.cardGray, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Picker("성별", selection: $gender) {
                ForEach(genderOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var traitsField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("자폐 정도/특성")
                .font(.system(size: 18, weight: .semibold))

            Menu {
                ForEach(autismTraitOptions, id: \.self) { option in
                    Button {
                        autismTraits = option
                    } label: {
                        if autismTraits == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(autismTraits.isEmpty ? "선택" : autismTraits)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(autismTraits.isEmpty ? AICOTheme.textGray : Color.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AICOTheme.textGray)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(16)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            }
        }
    }

    private var registerButton: some View {
        Button {
            saveRecipient()
        } label: {
            Text("등록하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AICOTheme.primaryOrange, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 25)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(AICOTheme.appBackground)
    }

    private func saveRecipient() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            validationMessage = "이름 또는 닉네임을 입력해주세요."
            return
        }

        let age = Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
        let normalizedGender = gender == "기타/미선택" ? nil : gender
        let trimmedTraits = autismTraits.trimmingCharacters(in: .whitespacesAndNewlines)

        let recipient = RecipientProfile(
            nickname: trimmedNickname,
            age: age,
            gender: normalizedGender,
            autismTraits: trimmedTraits.isEmpty ? nil : trimmedTraits,
            profileImageName: profileImageName
        )

        modelContext.insert(recipient)

        do {
            try modelContext.save()
            didSaveRecipient = true
            sessionState.selectRecipient(recipient)
            validationMessage = nil
        } catch {
            modelContext.delete(recipient)
            validationMessage = "대상자 정보를 저장하지 못했어요. 다시 시도해주세요."
        }
    }

    private func sanitizedAgeText(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(2))
    }

    @MainActor
    private func saveSelectedProfileImage() async {
        guard let selectedPhotoItem else { return }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                return
            }
            let previousImageName = profileImageName
            profileImageName = try ImageStorageService.saveImageData(data, prefix: "recipient")
            ImageStorageService.deleteImage(named: previousImageName)
        } catch {
            validationMessage = "이미지를 불러오지 못했어요. 다시 선택해주세요."
        }

        self.selectedPhotoItem = nil
    }
}

#Preview {
    NavigationStack {
        RecipientRegistrationView()
            .environmentObject(AnonymousSessionState())
    }
}
