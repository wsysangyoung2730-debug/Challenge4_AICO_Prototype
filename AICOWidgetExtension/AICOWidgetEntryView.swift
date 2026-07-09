import SwiftUI
import WidgetKit

struct AICOWidgetEntryView: View {
    let entry: AICOWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var quickRecordURL: URL {
        if let recipientId = entry.snapshot.defaultRecipientId {
            URL(string: "aico://quick-record?recipientId=\(recipientId)")!
        } else {
            URL(string: "aico://quick-record")!
        }
    }

    private var recipientSelectURL: URL {
        URL(string: "aico://select-recipient-for-record")!
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        Link(destination: quickRecordURL) {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.snapshot.defaultRecipientName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Label("기록", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AICOWidgetTheme.primaryOrange)
                    .clipShape(Capsule())
            }
            .padding()
            .containerBackground(AICOWidgetTheme.softBackground, for: .widget)
        }
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Link(destination: recipientSelectURL) {
                HStack(spacing: 4) {
                    Text(entry.snapshot.defaultRecipientName)
                        .font(.headline)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("오늘 기록 \(entry.snapshot.todayRecordCount)회")
                    .font(.title3)
                    .fontWeight(.bold)

                if let behavior = entry.snapshot.mostFrequentBehavior {
                    Text("\(behavior)이 반복 기록되었어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("아직 오늘 기록이 없어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Link(destination: quickRecordURL) {
                Label("기록하기", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(AICOWidgetTheme.primaryOrange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .containerBackground(AICOWidgetTheme.softBackground, for: .widget)
    }
}

private enum AICOWidgetTheme {
    static let primaryOrange = Color(red: 0.95, green: 0.43, blue: 0.16)
    static let softBackground = Color(red: 1.0, green: 0.97, blue: 0.92)
}
