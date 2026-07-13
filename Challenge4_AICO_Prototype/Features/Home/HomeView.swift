import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionState: AnonymousSessionState
    @Query(sort: \RecordEntry.createdAt, order: .reverse) private var records: [RecordEntry]
    @Query(sort: \RecipientProfile.createdAt) private var recipients: [RecipientProfile]

    @State private var selectedInfoItem: HomeInfoFeedItem?
    @State private var badgeReplayTrigger = 0

    private var recentRecords: [RecordEntry] {
        Array(records.prefix(5))
    }

    private var weeklyRecords: [RecordEntry] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    private var weeklyRecordCount: Int {
        weeklyRecords.count
    }

    private var monthlyRecordCount: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }.count
    }

    private var selectedRecipientName: String {
        recipients.first?.nickname ?? "카이"
    }

    private var weeklyRecordRecipients: [RecipientProfile] {
        guard !weeklyRecords.isEmpty else { return [] }

        let recordsByRecipient = Dictionary(grouping: weeklyRecords, by: \.recipientId)
        let mostRecentIndexByRecipient = weeklyRecords.enumerated().reduce(into: [UUID: Int]()) { result, item in
            if result[item.element.recipientId] == nil {
                result[item.element.recipientId] = item.offset
            }
        }

        return recordsByRecipient
            .map { (recipientId: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return (mostRecentIndexByRecipient[$0.recipientId] ?? Int.max)
                        < (mostRecentIndexByRecipient[$1.recipientId] ?? Int.max)
                }
                return $0.count > $1.count
            }
            .compactMap { item in
                recipients.first { $0.id == item.recipientId }
            }
    }

    private let feedItems = [
        HomeInfoFeedItem(
            title: "A/B/C 관찰기록 알아보기",
            summary: "아이코",
            detail: "A는 행동 전 상황, B는 관찰된 행동이나 신호, C는 이후 대응과 결과를 뜻합니다. AICO는 이 흐름을 보호자가 부담 없이 정리할 수 있게 돕는 방향으로 설계하고 있습니다.",
            systemImage: "pencil"
        ),
        HomeInfoFeedItem(
            title: "우리 아이의 행동 잘 관찰하기",
            summary: "아이코",
            detail: "기록이 충분히 쌓이면 아카이브와 리포트에서 자주 나타나는 상황, 행동, 대응을 다시 확인할 수 있습니다. 반복되는 흐름을 차분히 확인해보세요.",
            systemImage: "magnifyingglass"
        ),
        HomeInfoFeedItem(
            title: "기록으로 병원 상담 준비하기",
            summary: "아이코",
            detail: "상담 전 최근 기록을 돌아보면 상황, 행동, 대응을 더 구체적으로 설명할 수 있습니다. 민감한 정보가 포함될 수 있으니 공유 범위는 신중히 확인해주세요.",
            systemImage: "clipboard"
        )
    ]

    var body: some View {
        ZStack {
            AICOTheme.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    headerSection
                    recentRecordsSection
                    weeklyReportSection
                    informationFeedSection
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            if !sessionState.hasSeenHomeTutorial {
                HomeTutorialOverlayView {
                    sessionState.completeHomeTutorial()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedInfoItem) { item in
            HomeInfoFeedDetailView(item: item)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 14) {
                HStack(spacing: 10) {
                    Button {
                        badgeReplayTrigger += 1
                    } label: {
                        Image("AICOStar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("주간 기록 배지 애니메이션 다시 보기")

                    HomeWeeklyBadgeText(
                        weeklyCount: weeklyRecordCount,
                        monthlyCount: monthlyRecordCount,
                        hasPlayedAnimation: sessionState.hasPlayedHomeBadgeAnimationThisSession,
                        replayTrigger: badgeReplayTrigger
                    ) {
                        sessionState.hasPlayedHomeBadgeAnimationThisSession = true
                    }
                }
                .frame(height: 58, alignment: .center)

                Spacer()

                HStack(spacing: 10) {
                    Button {
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("알림")

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image("AICOLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("설정")
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(selectedRecipientName)맘")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AICOTheme.primaryOrange)
                    + Text(" 님,")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("오늘도 힘내보아요")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                Image("AICOcomponent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
            }
        }
        .padding(.horizontal, 24)
    }

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeSectionHeader(
                title: "최근 기록",
                subtitle: "최근 5개 기록을 빠르게 확인해보세요"
            )

            if recentRecords.isEmpty {
                HomeEmptyCard(
                    title: "아직 기록이 없어요",
                    message: "기록을 시작하면 최근 기록이 이곳에 보여요.",
                    systemImage: "clock"
                )
                .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentRecords) { record in
                            NavigationLink {
                                RecordDetailView(
                                    record: record,
                                    recipientName: recipientName(for: record)
                                )
                            } label: {
                                RecentRecordPreviewCard(
                                    record: record,
                                    recipient: recipient(for: record),
                                    fallbackRecipientName: selectedRecipientName
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private var weeklyReportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeSectionHeader(
                title: "핵심 주간 리포트",
                subtitle: "이번주 핵심 정보를 빠르게 확인해보세요"
            )

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TotalRecordCard(count: weeklyRecordCount, recipients: weeklyRecordRecipients)
                    SatisfactionCard(score: weeklySatisfactionScore)
                }

                TopCategoryCard(
                    stage: "A",
                    title: "Top 3",
                    items: topItems(in: weeklyRecords.flatMap(\.antecedentCategories))
                )

                TopCategoryCard(
                    stage: "B",
                    title: "Top 3",
                    items: topItems(in: weeklyRecords.flatMap(\.behaviorCategories))
                )
            }
            .padding(8)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
            .padding(.horizontal, 24)
        }
    }

    private var informationFeedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeSectionHeader(
                title: "정보 피드",
                subtitle: "아이코와 함께 똑똑한 보호자가 되어보세요"
            )

            VStack(spacing: 12) {
                ForEach(feedItems) { item in
                    Button {
                        selectedInfoItem = item
                    } label: {
                        HomeInfoFeedCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var weeklySatisfactionScore: Double {
        guard !weeklyRecords.isEmpty else { return 0 }
        let consequenceCount = weeklyRecords.flatMap(\.consequenceCategories).count
        let score = 3.2 + min(Double(consequenceCount), 9) * 0.2
        return min(score, 5.0)
    }

    private func recipientName(for record: RecordEntry) -> String {
        recipient(for: record)?.nickname ?? selectedRecipientName
    }

    private func recipient(for record: RecordEntry) -> RecipientProfile? {
        recipients.first { $0.id == record.recipientId }
    }

    private func topItems(in names: [String]) -> [String] {
        let items = Dictionary(grouping: names, by: { $0 })
            .map { (name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.name < $1.name
                }
                return $0.count > $1.count
            }
            .map(\.name)

        return Array(items.prefix(3))
    }
}

private struct HomeWeeklyBadgeText: View {
    let weeklyCount: Int
    let monthlyCount: Int
    let hasPlayedAnimation: Bool
    let replayTrigger: Int
    let markAnimationPlayed: () -> Void

    private let characterTypingDelay: UInt64 = 42_000_000
    private let completedMessagePause: UInt64 = 950_000_000

    @State private var currentMessage: BadgeMessage
    @State private var typedCount: Int
    @State private var typingTask: Task<Void, Never>?

    init(
        weeklyCount: Int,
        monthlyCount: Int,
        hasPlayedAnimation: Bool,
        replayTrigger: Int,
        markAnimationPlayed: @escaping () -> Void
    ) {
        self.weeklyCount = weeklyCount
        self.monthlyCount = monthlyCount
        self.hasPlayedAnimation = hasPlayedAnimation
        self.replayTrigger = replayTrigger
        self.markAnimationPlayed = markAnimationPlayed

        let finalMessage = BadgeMessage.weekly(count: weeklyCount)
        _currentMessage = State(initialValue: finalMessage)
        _typedCount = State(initialValue: finalMessage.characterCount)
    }

    var body: some View {
        renderedText
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: 168, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .onAppear {
                guard !hasPlayedAnimation else {
                    setFinalMessage()
                    return
                }
                startTypingAnimation()
            }
            .onDisappear {
                typingTask?.cancel()
                typingTask = nil
            }
            .onChange(of: weeklyCount) { _, _ in
                guard hasPlayedAnimation || typingTask == nil else { return }
                setFinalMessage()
            }
            .onChange(of: replayTrigger) { _, _ in
                startTypingAnimation()
            }
    }

    private var renderedText: Text {
        let visibleCount = min(typedCount, currentMessage.characterCount)

        if let emphasized = currentMessage.emphasizedText {
            let prefix = currentMessage.prefixText
            let suffix = currentMessage.suffixText
            let prefixCount = prefix.count
            let emphasizedCount = emphasized.count

            let visiblePrefix = String(prefix.prefix(visibleCount))
            let emphasizedVisibleCount = max(0, min(visibleCount - prefixCount, emphasizedCount))
            let visibleEmphasis = String(emphasized.prefix(emphasizedVisibleCount))
            let suffixVisibleCount = max(0, visibleCount - prefixCount - emphasizedCount)
            let visibleSuffix = String(suffix.prefix(suffixVisibleCount))

            return Text(visiblePrefix).foregroundStyle(.black)
            + Text(visibleEmphasis).foregroundStyle(AICOTheme.primaryOrange)
            + Text(visibleSuffix).foregroundStyle(.black)
        }

        return Text(String(currentMessage.fullText.prefix(visibleCount)))
            .foregroundStyle(.black)
    }

    private func startTypingAnimation() {
        typingTask?.cancel()
        markAnimationPlayed()

        typingTask = Task {
            let encouragements = [
                BadgeMessage.plain("오늘도 천천히 살펴봐요"),
                BadgeMessage.plain("작은 기록이 큰 도움이 돼요"),
                BadgeMessage.plain("잘하고 있어요"),
                BadgeMessage.plain("차근차근 확인해봐요")
            ].shuffled().prefix(2)

            let messages = [
                BadgeMessage.monthly(count: monthlyCount),
                BadgeMessage.weekly(count: weeklyCount)
            ] + encouragements + [
                BadgeMessage.weekly(count: weeklyCount)
            ]

            for message in messages {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    currentMessage = message
                    typedCount = 0
                }

                for count in 0...message.characterCount {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        typedCount = count
                    }
                    try? await Task.sleep(nanoseconds: characterTypingDelay)
                }

                try? await Task.sleep(nanoseconds: completedMessagePause)
            }

            await MainActor.run {
                setFinalMessage()
                typingTask = nil
            }
        }
    }

    private func setFinalMessage() {
        let finalMessage = BadgeMessage.weekly(count: weeklyCount)
        currentMessage = finalMessage
        typedCount = finalMessage.characterCount
    }
}

private struct BadgeMessage {
    let prefixText: String
    let emphasizedText: String?
    let suffixText: String

    var fullText: String {
        prefixText + (emphasizedText ?? "") + suffixText
    }

    var characterCount: Int {
        fullText.count
    }

    static func weekly(count: Int) -> BadgeMessage {
        BadgeMessage(prefixText: "이번 주 ", emphasizedText: "\(count)회", suffixText: " 기록했어요")
    }

    static func monthly(count: Int) -> BadgeMessage {
        BadgeMessage(prefixText: "이번 달 ", emphasizedText: "\(count)회", suffixText: " 기록했어요")
    }

    static func plain(_ text: String) -> BadgeMessage {
        BadgeMessage(prefixText: text, emphasizedText: nil, suffixText: "")
    }
}

private struct HomeSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)

            Text(subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)
        }
        .padding(.horizontal, 24)
    }
}

private struct RecentRecordPreviewCard: View {
    let record: RecordEntry
    let recipient: RecipientProfile?
    let fallbackRecipientName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    HomeRecipientAvatar(fileName: recipient?.profileImageName, size: 36)

                    Text(recipientName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.createdAt.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute()))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AICOTheme.textGray)
                        .lineLimit(1)

                    Text(mainBehavior)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            categoryArea

            Text(noteText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.darkGray)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 206, height: 276, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
    }

    private var recipientName: String {
        recipient?.nickname ?? fallbackRecipientName
    }

    private var mainBehavior: String {
        record.behaviorCategories.first ?? "행동을 기록했어요"
    }

    private var noteText: String {
        guard let note = record.note, !note.isEmpty else {
            return "기록을 자세히 확인해보세요."
        }
        return note
    }

    private var categoryArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(categoryRows, id: \.stage) { row in
                CategoryPair(stage: row.stage, text: row.text)
            }
        }
        .frame(height: categoryAreaHeight, alignment: .topLeading)
    }

    private var categoryRows: [(stage: String, text: String)] {
        [
            ("A", record.antecedentCategories.first),
            ("B", record.behaviorCategories.first),
            ("C", record.consequenceCategories.first)
        ]
        .compactMap { row in
            guard let text = row.1, !text.isEmpty else { return nil }
            return (row.0, text)
        }
    }

    private var categoryAreaHeight: CGFloat {
        98
    }
}

private struct HomeRecipientAvatar: View {
    let fileName: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let image = ImageStorageService.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("AICOLogo")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct CategoryPair: View {
    let stage: String
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Text(stage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AICOTheme.primaryOrange, in: Circle())

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AICOTheme.primaryOrange)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(AICOTheme.primaryOrange.opacity(0.1), in: Capsule())
        }
    }
}

private struct TotalRecordCard: View {
    let count: Int
    let recipients: [RecipientProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("총 기록")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                WeeklyProfileStack(recipients: recipients)
            }

            Spacer()

            Text(String(format: "%02d", count))
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(.white)
            + Text(" 건")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .background(AICOTheme.primaryOrange, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WeeklyProfileStack: View {
    let recipients: [RecipientProfile]

    private var visibleRecipients: [RecipientProfile] {
        Array(recipients.prefix(3))
    }

    private var remainingCount: Int {
        max(recipients.count - visibleRecipients.count, 0)
    }

    var body: some View {
        HStack(spacing: -8) {
            if visibleRecipients.isEmpty {
                avatar(fileName: nil)
            } else {
                ForEach(visibleRecipients) { recipient in
                    avatar(fileName: recipient.profileImageName)
                }

                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AICOTheme.primaryOrange)
                        .frame(width: 30, height: 30)
                        .background(.white, in: Circle())
                        .overlay {
                            Circle().stroke(.white, lineWidth: 1)
                        }
                }
            }
        }
    }

    private func avatar(fileName: String?) -> some View {
        HomeRecipientAvatar(fileName: fileName, size: 30)
            .overlay {
                Circle().stroke(.white, lineWidth: 1)
            }
    }
}

private struct SatisfactionCard: View {
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("C")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(AICOTheme.primaryOrange, in: Circle())

                Text("만족도")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AICOTheme.primaryOrange)
            }

            Spacer()

            Text(score > 0 ? String(format: "%.1f", score) : "0.0")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(AICOTheme.primaryOrange)
            + Text(" / 5.0")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AICOTheme.primaryOrange)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .background(AICOTheme.primaryOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TopCategoryCard: View {
    let stage: String
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(stage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(AICOTheme.primaryOrange, in: Circle())

                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
            }

            FlexibleChipLayout(spacing: 8, rowSpacing: 8) {
                ForEach(Array(displayItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                        Text(item)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AICOTheme.primaryOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AICOTheme.primaryOrange.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AICOTheme.cardGray, lineWidth: 1)
        }
    }

    private var displayItems: [String] {
        items.isEmpty ? ["기록 대기"] : items
    }
}

private struct HomeInfoFeedCard: View {
    let item: HomeInfoFeedItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 48, height: 48)
                .background(AICOTheme.primaryOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                Text(item.summary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AICOTheme.textGray)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
    }
}

private struct HomeEmptyCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AICOTheme.primaryOrange)
                .frame(width: 48, height: 48)
                .background(AICOTheme.primaryOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 0)
    }
}

private struct FlexibleChipLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0, lineWidth + spacing + size.width > maxWidth {
                totalHeight += lineHeight + rowSpacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += lineWidth == 0 ? size.width : spacing + size.width
                lineHeight = max(lineHeight, size.height)
            }
        }

        return CGSize(width: maxWidth, height: totalHeight + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + rowSpacing
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AnonymousSessionState())
        .modelContainer(SwiftDataContainer.shared)
}
