import AVKit
import PhotosUI
import SwiftData
import SwiftUI

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: RecordEntry
    let recipientName: String
    let recipientImageName: String?

    @State private var draftNote: String
    @State private var isEditingNote = false
    @State private var isShowingDeleteAlert = false
    @State private var isShowingMediaPicker = false
    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var mediaNameToReplace: String?

    private let consequenceResponseNames: Set<String> = [
        "음식/음료 제공", "휴식 제공", "공간 이동", "안아줌",
        "거리둠", "그림/시각자료", "활동 전환"
    ]

    init(
        record: RecordEntry,
        recipientName: String,
        recipientImageName: String? = nil
    ) {
        self.record = record
        self.recipientName = recipientName
        self.recipientImageName = recipientImageName
        _draftNote = State(initialValue: record.note ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                titleArea
                occurrenceDateRow
                categoryCard
                noteSection
                mediaSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(AICOTheme.appBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("기록 삭제")
            }
        }
        .photosPicker(
            isPresented: $isShowingMediaPicker,
            selection: $selectedMediaItem,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: selectedMediaItem) {
            Task { await saveSelectedMedia() }
        }
        .alert("이 기록을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("삭제하면 이 기록과 첨부 파일은 되돌릴 수 없어요.")
        }
    }

    private var titleArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                recipientAvatar

                Text(recipientName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("· \(Self.dateFormatter.string(from: record.createdAt))")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AICOTheme.textGray)
            }

            Text(record.behaviorCategories.first ?? "행동 기록")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var recipientAvatar: some View {
        if let image = ImageStorageService.image(for: recipientImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(AICOTheme.primaryOrange)
                .accessibilityHidden(true)
        }
    }

    private var occurrenceDateRow: some View {
        HStack {
            Text("상황 발생일")
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Text(Self.dateFormatter.string(from: record.effectiveRecordDate))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AICOTheme.textGray)
        }
    }

    private var categoryCard: some View {
        VStack(spacing: 16) {
            categoryRow(title: "선행 상황", value: record.antecedentCategories.first)
            categoryRow(title: "행동", value: record.behaviorCategories.first)
            categoryRow(title: "보호자 대응", value: responseCategory)
            categoryRow(title: "대응 결과", value: resultCategory)
        }
        .padding(16)
        .background(AICOTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    private func categoryRow(title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))

            Spacer(minLength: 8)

            Text(value ?? "없음")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(value == nil ? AICOTheme.textGray : AICOTheme.primaryOrange)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    value == nil ? Color.clear : AICOTheme.primaryOrange.opacity(0.1),
                    in: Capsule()
                )
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("추가 기록")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Button(isEditingNote ? "완료" : "편집") {
                    if isEditingNote {
                        saveNote()
                    } else {
                        isEditingNote = true
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isEditingNote ? AICOTheme.primaryOrange : AICOTheme.textGray)
            }

            Group {
                if isEditingNote {
                    TextEditor(text: $draftNote)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 88)
                } else {
                    Text(displayNote)
                        .foregroundStyle(AICOTheme.darkGray)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .padding(16)
            .background(AICOTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private var mediaSection: some View {
        if let fileName = record.attachmentNames.first {
            RecordMediaView(
                fileName: fileName,
                onReplace: {
                    mediaNameToReplace = fileName
                    isShowingMediaPicker = true
                },
                onDelete: {
                    deleteMedia(named: fileName)
                }
            )
        } else {
            Button {
                mediaNameToReplace = nil
                isShowingMediaPicker = true
            } label: {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        Image(systemName: "camera")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(AICOTheme.textGray)
                            .frame(width: 48, height: 48)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("사진 또는 영상 등록")
        }
    }

    private var responseCategory: String? {
        record.consequenceCategories.first { consequenceResponseNames.contains($0) }
    }

    private var resultCategory: String? {
        record.consequenceCategories.first { !consequenceResponseNames.contains($0) }
    }

    private var displayNote: String {
        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "추가 기록이 없어요." : trimmed
    }

    private func saveNote() {
        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        record.note = trimmed.isEmpty ? nil : trimmed
        draftNote = trimmed
        isEditingNote = false
        saveModelContext()
    }

    private func deleteMedia(named fileName: String) {
        record.attachmentNames.removeAll { $0 == fileName }
        ImageStorageService.deleteImage(named: fileName)
        saveModelContext()
    }

    @MainActor
    private func saveSelectedMedia() async {
        guard let selectedMediaItem else { return }
        defer {
            self.selectedMediaItem = nil
            mediaNameToReplace = nil
        }

        do {
            guard let newFileName = try await ImageStorageService.saveMedia(
                from: selectedMediaItem,
                prefix: "record"
            ) else { return }

            if let mediaNameToReplace,
               let index = record.attachmentNames.firstIndex(of: mediaNameToReplace) {
                record.attachmentNames[index] = newFileName
                ImageStorageService.deleteImage(named: mediaNameToReplace)
            } else {
                record.attachmentNames = [newFileName]
            }

            saveModelContext()
        } catch {
            assertionFailure("Failed to save selected media: \(error.localizedDescription)")
        }
    }

    private func deleteRecord() {
        record.attachmentNames.forEach { ImageStorageService.deleteImage(named: $0) }
        modelContext.delete(record)
        saveModelContext()
        dismiss()
    }

    private func saveModelContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save record: \(error.localizedDescription)")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter
    }()
}

private struct RecordMediaView: View {
    let fileName: String
    let onReplace: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            if ImageStorageService.isVideo(fileName) {
                RecordVideoView(
                    fileName: fileName,
                    onReplace: onReplace,
                    onDelete: onDelete
                )
            } else if let image = ImageStorageService.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        mediaMenu
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AICOTheme.cardGray)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(AICOTheme.textGray)
                    }
                    .overlay(alignment: .topTrailing) {
                        mediaMenu
                    }
            }
        }
    }

    private var mediaMenu: some View {
        Menu {
            Button {
                onReplace()
            } label: {
                Label("사진 보관함", systemImage: "photo.on.rectangle")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("첨부 파일 메뉴")
    }
}

private struct RecordVideoView: View {
    let fileName: String
    let onReplace: () -> Void
    let onDelete: () -> Void

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                AICOTheme.cardGray
            }

            if !isPlaying {
                Color.black.opacity(0.5)

                Button {
                    isPlaying = true
                    player?.play()
                } label: {
                    Image(systemName: "play")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("영상 재생")
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            Menu {
                Button {
                    onReplace()
                } label: {
                    Label("사진 보관함", systemImage: "photo.on.rectangle")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("첨부 파일 메뉴")
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .task {
            guard player == nil, let url = ImageStorageService.fileURL(for: fileName) else { return }
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
        }
    }
}
