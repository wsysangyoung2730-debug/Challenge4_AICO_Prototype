import SwiftUI

struct PlaceholderCardView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(AICOTheme.primaryOrange)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(AICOTheme.textGray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AICOTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AICOTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AICOTheme.cornerRadius)
                .stroke(AICOTheme.primaryOrange.opacity(0.12))
        }
    }
}

#Preview {
    PlaceholderCardView(
        title: "최근 기록",
        message: "저장한 기록이 이곳에 표시됩니다.",
        systemImage: "clock.fill"
    )
    .padding()
    .background(AICOTheme.softBackground)
}

struct MainHeaderActions: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState

    let recipients: [RecipientProfile]
    var showsCalendar = false
    var onCalendarTap: (() -> Void)?
    var onProfileTap: (() -> Void)?

    @State private var showsRecipientPicker = false

    private var selectedRecipient: RecipientProfile? {
        recipients.first { $0.id == sessionState.selectedRecipientID } ?? recipients.first
    }

    var body: some View {
        HStack(spacing: 10) {
            if showsCalendar {
                Button {
                    onCalendarTap?()
                } label: {
                    circularIcon("calendar")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("기록 날짜 변경")
            } else {
                NavigationLink {
                    SettingsView()
                } label: {
                    circularIcon("gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
            }

            Button {
                if let onProfileTap {
                    onProfileTap()
                } else {
                    showsRecipientPicker = true
                }
            } label: {
                recipientAvatar
            }
            .buttonStyle(.plain)
            .accessibilityLabel("프로필 변경")
            .disabled(recipients.isEmpty)
        }
        .sheet(isPresented: $showsRecipientPicker) {
            RecipientSwitcherSheet(recipients: recipients)
        }
        .onAppear {
            normalizeSelection()
        }
        .onChange(of: recipients.map(\.id)) {
            normalizeSelection()
        }
    }

    private func normalizeSelection() {
        if !recipients.contains(where: { $0.id == sessionState.selectedRecipientID }) {
            sessionState.selectedRecipientID = recipients.first?.id
        }
    }

    private func circularIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.black)
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private var recipientAvatar: some View {
        if let selectedRecipient,
           let image = ImageStorageService.image(for: selectedRecipient.profileImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 48, height: 48)
                .background(AICOTheme.softOrangeBackground, in: Circle())
        }
    }
}

private struct RecipientSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionState: AnonymousSessionState

    let recipients: [RecipientProfile]

    var body: some View {
        NavigationStack {
            List(recipients) { recipient in
                Button {
                    sessionState.selectRecipient(recipient)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        avatar(for: recipient)

                        Text(recipient.nickname)
                            .foregroundStyle(.primary)

                        Spacer()

                        if recipient.id == sessionState.selectedRecipientID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AICOTheme.primaryOrange)
                        }
                    }
                }
            }
            .navigationTitle("프로필 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func avatar(for recipient: RecipientProfile) -> some View {
        if let image = ImageStorageService.image(for: recipient.profileImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 44, height: 44)
        }
    }
}
