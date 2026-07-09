import SwiftUI

struct SettingsView: View {
    private let rows = [
        ("대상자 관리", "person.crop.circle"),
        ("기록 카테고리 관리", "tag.fill"),
        ("알림 ON/OFF", "bell.fill"),
        ("앱 데이터 전체 삭제", "trash.fill")
    ]

    var body: some View {
        List {
            Section {
                ForEach(rows, id: \.0) { row in
                    HStack(spacing: 12) {
                        Image(systemName: row.1)
                            .foregroundStyle(AICOTheme.primaryOrange)
                            .frame(width: 24)

                        Text(row.0)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .navigationTitle("설정")
        .scrollContentBackground(.hidden)
        .background(AICOTheme.softBackground)
    }
}

#Preview {
    SettingsView()
}
