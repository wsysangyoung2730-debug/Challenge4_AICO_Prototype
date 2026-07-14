import SwiftData
import SwiftUI

struct QuickRecordRecipientPickerView: View {
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]

    var body: some View {
        List {
            Section {
                if recipients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("등록된 대상자가 없어요.")
                            .font(.headline)

                        Text("기록을 시작하면 먼저 대상자 등록 화면으로 안내됩니다.")
                            .font(.subheadline)
                            .foregroundStyle(AICOTheme.textGray)

                        NavigationLink("대상자 등록으로 이동") {
                            RecordingEntryView()
                        }
                        .foregroundStyle(AICOTheme.primaryOrange)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(recipients) { recipient in
                        NavigationLink {
                            RecordingEntryView(preferredRecipientID: recipient.id)
                        } label: {
                            HStack(spacing: 12) {
                                quickAvatar(fileName: recipient.profileImageName)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipient.nickname)
                                        .font(.headline)

                                    Text(todaySummary(for: recipient))
                                        .font(.caption)
                                        .foregroundStyle(AICOTheme.textGray)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("기록할 대상자 선택")
            }
        }
        .navigationTitle("빠른 기록")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
    }

    private func todaySummary(for recipient: RecipientProfile) -> String {
        let calendar = Calendar.current
        let count = records.filter {
            $0.recipientId == recipient.id && calendar.isDateInToday($0.createdAt)
        }.count
        return "오늘 기록 \(count)회"
    }

    private func quickAvatar(fileName: String?) -> some View {
        Group {
            if let image = ImageStorageService.image(for: fileName) {
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
        .frame(width: 42, height: 42)
        .clipShape(Circle())
    }
}
