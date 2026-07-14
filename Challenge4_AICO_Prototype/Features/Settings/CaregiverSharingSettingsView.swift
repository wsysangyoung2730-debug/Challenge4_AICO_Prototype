import CloudKit
import SwiftUI
import UIKit

enum CaregiverSharingState {
    case notStarted
    case adminRoom
    case joinedRoom
}

enum CaregiverSharingRole {
    case admin
    case invited

    var title: String {
        switch self {
        case .admin: "관리자"
        case .invited: "초대받은 보호자"
        }
    }
}

struct MockCaregiverParticipant: Identifiable, Equatable {
    let id: UUID
    let name: String
    let roleDescription: String
    let status: String
    let isCurrentUser: Bool

    init(
        id: UUID = UUID(),
        name: String,
        roleDescription: String,
        status: String,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.roleDescription = roleDescription
        self.status = status
        self.isCurrentUser = isCurrentUser
    }
}

struct MockCaregiverSharingRoom: Identifiable {
    let id: UUID
    let childName: String
    var status: String
    var participants: [MockCaregiverParticipant]

    init(
        id: UUID = UUID(),
        childName: String,
        status: String,
        participants: [MockCaregiverParticipant]
    ) {
        self.id = id
        self.childName = childName
        self.status = status
        self.participants = participants
    }
}

struct CaregiverSharingSettingsView: View {
    @State private var sharingState: CaregiverSharingState = .notStarted
    @State private var adminRoom = MockCaregiverSharingRoom.adminPreview
    @State private var joinedRoom = MockCaregiverSharingRoom.joinedPreview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                switch sharingState {
                case .notStarted:
                    initialStateContent
                case .adminRoom:
                    roomListContent(room: $adminRoom, role: .admin)
                case .joinedRoom:
                    roomListContent(room: $joinedRoom, role: .invited)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("보호자 공유 설정")
        .navigationBarTitleDisplayMode(.inline)
        .background(AICOTheme.softBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("함께 기록을 확인할 보호자를 연결할 수 있어요.")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)

            Text("현재 화면은 CloudKit 공유 기능을 준비하기 위한 프로토타입 UI예요. 실제 초대, 동기화, 원격 데이터 변경은 아직 실행하지 않습니다.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AICOTheme.darkGray)
                .lineSpacing(3)
        }
    }

    private var initialStateContent: some View {
        VStack(spacing: 12) {
            NavigationLink {
                CaregiverInviteView {
                    adminRoom = .adminPreview
                    sharingState = .adminRoom
                }
            } label: {
                CaregiverLargeActionCard(
                    title: "새로운 공유방 만들기",
                    message: "내가 관리자가 되어 다른 보호자를 초대하는 흐름을 확인해요.",
                    systemImage: "plus.circle.fill"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                CaregiverJoinRoomView {
                    joinedRoom = .joinedPreview
                    sharingState = .joinedRoom
                }
            } label: {
                CaregiverLargeActionCard(
                    title: "기존 공유방 참여하기",
                    message: "초대받은 보호자 입장에서 참여 화면을 확인해요.",
                    systemImage: "person.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func roomListContent(
        room: Binding<MockCaregiverSharingRoom>,
        role: CaregiverSharingRole
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("참여중인 공유방")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)

            NavigationLink {
                CaregiverSharingRoomDetailView(room: room, currentUserRole: role)
            } label: {
                CaregiverSharingRoomCard(room: room.wrappedValue, role: role)
            }
            .buttonStyle(.plain)

            Text("이 목록은 공유방 상태를 미리 확인하기 위한 mock 데이터입니다.")
                .font(.footnote)
                .foregroundStyle(AICOTheme.textGray)
        }
    }
}

struct CaregiverInviteView: View {
    @State private var status = "대기 중"
    @State private var pendingShare: CKShare?
    @State private var showShareSheet = false

    let onMockRoomCreated: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("초대 링크를 만들어 상대 보호자에게 보내세요.")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AICOTheme.primaryOrange)

                    Text("공유 링크 만들고 초대하기")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("버튼을 누르면 초대창이 떠요. 메시지·메일 또는 '링크 복사'로 상대에게 보내면, 상대가 링크를 눌러 수락합니다.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AICOTheme.darkGray)
                        .lineSpacing(3)

                    Button {
                        createShare()
                    } label: {
                        Text("공유 링크 만들고 초대하기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AICOTheme.primaryOrange, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(AICOTheme.textGray)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)

                Text("연결이 끝나면 홈 화면의 '동기화' 버튼으로 서로의 오늘 기록을 주고받아요.")
                    .font(.footnote)
                    .foregroundStyle(AICOTheme.textGray)
                    .lineSpacing(3)
            }
            .padding(20)
        }
        .navigationTitle("보호자 초대")
        .navigationBarTitleDisplayMode(.inline)
        .background(AICOTheme.softBackground)
        .sheet(isPresented: $showShareSheet, onDismiss: { onMockRoomCreated() }) {
            if let share = pendingShare {
                CloudSharingView(share: share, container: GuardianSyncManager.container)
            }
        }
    }

    private func createShare() {
        status = "공유 준비 중…"
        Task {
            do {
                let share = try await GuardianSyncManager.setupOwnerShare()
                await MainActor.run {
                    pendingShare = share
                    showShareSheet = true
                    status = "초대창에서 상대에게 링크를 보내세요."
                }
            } catch {
                await MainActor.run { status = "실패: \(error.localizedDescription)" }
            }
        }
    }
}

struct CaregiverJoinRoomView: View {
    let onMockRoomJoined: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("초대받은 보호자는 따로 입력할 게 없어요.")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AICOTheme.primaryOrange)

                    Text("받은 초대 링크를 누르면 끝")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("초대한 보호자가 메시지·메일로 보낸 링크를 누르면 자동으로 이 공유방에 연결돼요. 그다음 홈 화면의 '동기화' 버튼으로 서로의 오늘 기록을 주고받아요.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AICOTheme.darkGray)
                        .lineSpacing(3)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
            }
            .padding(20)
        }
        .navigationTitle("공유방 참여하기")
        .navigationBarTitleDisplayMode(.inline)
        .background(AICOTheme.softBackground)
    }
}

struct CaregiverSharingRoomDetailView: View {
    @Binding var room: MockCaregiverSharingRoom
    let currentUserRole: CaregiverSharingRole

    @State private var participantPendingRemoval: MockCaregiverParticipant?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(room.childName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)

                        Spacer()

                        Text(currentUserRole.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AICOTheme.primaryOrange)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(AICOTheme.softPeach, in: Capsule())
                    }

                    Text("\(room.participants.count)명 · \(room.status)")
                        .font(.subheadline)
                        .foregroundStyle(AICOTheme.darkGray)
                }
                .padding(.vertical, 8)
            }

            Section {
                ForEach(room.participants) { participant in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(participant.isCurrentUser ? AICOTheme.primaryOrange : AICOTheme.softPeach)
                            .frame(width: 42, height: 42)
                            .overlay {
                                Image(systemName: participant.isCurrentUser ? "person.fill" : "person")
                                    .foregroundStyle(participant.isCurrentUser ? .white : AICOTheme.primaryOrange)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(participant.name)
                                .font(.system(size: 16, weight: .semibold))

                            Text("\(participant.roleDescription) · \(participant.status)")
                                .font(.caption)
                                .foregroundStyle(AICOTheme.textGray)
                        }

                        Spacer()

                        if canRemove(participant) {
                            Button {
                                participantPendingRemoval = participant
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(AICOTheme.textGray)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(participant.name) 내보내기")
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("참여 보호자")
            } footer: {
                Text(currentUserRole == .admin ? "내보내기는 현재 mock 목록에서만 제거됩니다." : "초대받은 보호자는 참여자를 관리할 수 없습니다.")
            }
        }
        .navigationTitle("공유방 상세")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
        .alert(
            "보호자를 내보낼까요?",
            isPresented: Binding(
                get: { participantPendingRemoval != nil },
                set: { isPresented in
                    if !isPresented {
                        participantPendingRemoval = nil
                    }
                }
            )
        ) {
            Button("취소", role: .cancel) {
                participantPendingRemoval = nil
            }
            Button("내보내기", role: .destructive) {
                removePendingParticipant()
            }
        } message: {
            Text("이 보호자는 더 이상 공유방 기록을 확인할 수 없어요.")
        }
    }

    private func canRemove(_ participant: MockCaregiverParticipant) -> Bool {
        currentUserRole == .admin && !participant.isCurrentUser
    }

    private func removePendingParticipant() {
        guard let participantPendingRemoval else { return }
        room.participants.removeAll { $0.id == participantPendingRemoval.id }
        self.participantPendingRemoval = nil
    }
}

private struct CaregiverLargeActionCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 46, height: 46)
                .background(AICOTheme.softPeach, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AICOTheme.darkGray)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AICOTheme.textGray)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
    }
}

private struct CaregiverSharingRoomCard: View {
    let room: MockCaregiverSharingRoom
    let role: CaregiverSharingRole

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.childName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)

                    Text("\(room.participants.count)명")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AICOTheme.darkGray)
                }

                Spacer()

                Text(room.status)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(AICOTheme.primaryOrange.opacity(0.1), in: Capsule())
            }

            HStack {
                Label(role.title, systemImage: role == .admin ? "crown.fill" : "person.fill.checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AICOTheme.textGray)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AICOTheme.textGray)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
    }
}

private extension MockCaregiverSharingRoom {
    static var adminPreview: MockCaregiverSharingRoom {
        MockCaregiverSharingRoom(
            childName: "민준이",
            status: "연결 대기 중",
            participants: [
                MockCaregiverParticipant(name: "나", roleDescription: "관리자", status: "연결됨", isCurrentUser: true),
                MockCaregiverParticipant(name: "공유받은 보호자", roleDescription: "보호자", status: "초대 대기")
            ]
        )
    }

    static var joinedPreview: MockCaregiverSharingRoom {
        MockCaregiverSharingRoom(
            childName: "민준이",
            status: "연결됨",
            participants: [
                MockCaregiverParticipant(name: "공유방 관리자", roleDescription: "관리자", status: "연결됨"),
                MockCaregiverParticipant(name: "나", roleDescription: "초대받은 보호자", status: "연결됨", isCurrentUser: true)
            ]
        )
    }
}

// UICloudSharingController를 SwiftUI에서 쓰기 위한 래퍼 (초대 UI)
private struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("공유 저장 실패:", error)
        }
        func itemTitle(for csc: UICloudSharingController) -> String? { "AICO 보호자 공유" }
    }
}

#Preview {
    NavigationStack {
        CaregiverSharingSettingsView()
    }
}
