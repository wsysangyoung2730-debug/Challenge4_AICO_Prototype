import PhotosUI
import SwiftData
import SwiftUI

struct CaregiverRegistrationView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var relationship = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImageName: String?
    @State private var validationMessage: String?
    @State private var didSaveProfile = false

    private let relationshipOptions = ["부", "모", "조부", "조모", "기타"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                profilePhotoField
                nameField
                relationshipField
            }
            .padding(.horizontal, 24)
            .padding(.top, 72)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            registerButton
        }
        .background(AICOTheme.appBackground)
        .onChange(of: selectedPhotoItem) {
            Task { await saveSelectedProfileImage() }
        }
        .onDisappear {
            if !didSaveProfile {
                ImageStorageService.deleteImage(named: profileImageName)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("아이코를 시작하기에 앞서,\n보호자에 대해 알려주세요")
                .font(.system(size: 24, weight: .semibold))

            Text("기록 작성자와 보호자 정보를 구분하는 데 사용해요")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)
        }
    }

    private var profilePhotoField: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 12) {
                profileAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text("보호자 사진")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("선택하지 않으면 기본 이미지가 표시돼요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AICOTheme.textGray)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(profileImageName == nil ? "보호자 사진 선택" : "보호자 사진 변경")
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
                    Circle().stroke(Color(.separator), lineWidth: 1)
                }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            requiredLabel("이름/닉네임")

            TextField("예) 홍길동, 튼튼맘", text: $name)
                .font(.system(size: 16, weight: .medium))
                .padding(16)
                .background(AICOTheme.cardGray, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var relationshipField: some View {
        VStack(alignment: .leading, spacing: 12) {
            requiredLabel("대상자와의 관계")

            Menu {
                ForEach(relationshipOptions, id: \.self) { option in
                    Button {
                        relationship = option
                    } label: {
                        if relationship == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(relationship.isEmpty ? "선택" : relationship)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(relationship.isEmpty ? AICOTheme.textGray : Color.primary)

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

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.primary)
            Text("*")
                .foregroundStyle(AICOTheme.primaryOrange)
        }
        .font(.system(size: 18, weight: .semibold))
    }

    private var registerButton: some View {
        Button {
            saveProfile()
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

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !relationship.isEmpty else {
            validationMessage = "이름/닉네임과 대상자와의 관계를 입력해주세요."
            return
        }

        let profile = CaregiverProfile(
            name: trimmedName,
            relationship: relationship,
            profileImageName: profileImageName
        )
        modelContext.insert(profile)

        do {
            try modelContext.save()
            didSaveProfile = true
            validationMessage = nil
        } catch {
            modelContext.delete(profile)
            validationMessage = "보호자 정보를 저장하지 못했어요. 다시 시도해주세요."
        }
    }

    @MainActor
    private func saveSelectedProfileImage() async {
        guard let selectedPhotoItem else { return }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                return
            }
            let previousImageName = profileImageName
            profileImageName = try ImageStorageService.saveImageData(data, prefix: "caregiver")
            ImageStorageService.deleteImage(named: previousImageName)
        } catch {
            validationMessage = "이미지를 불러오지 못했어요. 다시 선택해주세요."
        }

        self.selectedPhotoItem = nil
    }
}

#Preview {
    CaregiverRegistrationView()
}
