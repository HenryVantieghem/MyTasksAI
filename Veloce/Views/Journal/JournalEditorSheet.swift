//
//  JournalEditorSheet.swift
//  Veloce
//
//  Immersive Full-Screen Journal Editor
//  Rich text formatting, media support, voice recording, and AI features
//

import SwiftUI
import SwiftData
import PencilKit
import PhotosUI

// MARK: - Journal Editor Sheet

struct JournalEditorSheet: View {
    @Bindable var viewModel: JournalFeedViewModel
    var entry: JournalEntry?
    var entryType: JournalEntryType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Editor State
    @State private var currentEntry: JournalEntry?
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: JournalMood?
    @State private var showMoodPicker = false
    @State private var gratitudeItems: [String] = ["", "", ""]

    // Media State
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showDrawingCanvas = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoAttachments: [PhotoAttachment] = []
    @State private var currentDrawing = PKDrawing()

    // Voice Recording State
    @State private var showVoiceRecorder = false
    @State private var voiceRecordings: [VoiceRecording] = []

    // Formatting State
    @State private var showFormattingToolbar = false
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    // AI State
    @State private var isAnalyzing = false
    @State private var aiSuggestion: String?

    // Animation State
    @State private var isLoaded = false
    @State private var keyboardHeight: CGFloat = 0

    @FocusState private var isContentFocused: Bool

    private var entryColor: Color {
        JournalColors.colorFor(entryType: currentEntry?.entryType ?? entryType)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Subtle parchment texture effect
                editorBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Entry Type Badge
                        entryTypeBadge
                            .padding(.top, Theme.Spacing.md)

                        // AI Prompt (for reflections)
                        if entryType == .reflection, let prompt = viewModel.dailyPrompt {
                            aiPromptSection(prompt: prompt)
                        }

                        // Title Field
                        titleField

                        // Gratitude Items (for gratitude entries)
                        if entryType == .gratitude {
                            gratitudeSection
                        }

                        // Content Area
                        contentEditor

                        // Media Section
                        if !photoAttachments.isEmpty || currentDrawing.bounds.size != .zero {
                            mediaSection
                        }

                        // Voice Recordings
                        if !voiceRecordings.isEmpty {
                            voiceRecordingsSection
                        }

                        // AI Suggestion
                        if let suggestion = aiSuggestion {
                            aiSuggestionCard(suggestion: suggestion)
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                }

                // Floating Toolbar
                VStack {
                    Spacer()
                    floatingToolbar
                        .padding(.horizontal, Theme.Spacing.screenPadding)
                        .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 20 : 20)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }

                ToolbarItem(placement: .principal) {
                    moodButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(entryColor)
                }
            }
            .onAppear {
                setupEntry()
                withAnimation(Theme.Animation.spring.delay(0.2)) {
                    isLoaded = true
                }
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task {
                    await loadPhotos(from: newItems)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    keyboardHeight = 0
                }
            }
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            )
            .sheet(isPresented: $showDrawingCanvas) {
                DrawingCanvasSheet(drawing: $currentDrawing)
            }
            .sheet(isPresented: $showVoiceRecorder) {
                VoiceRecorderSheet(recordings: $voiceRecordings)
            }
            .sheet(isPresented: $showMoodPicker) {
                MoodPickerSheet(selectedMood: $selectedMood, entryColor: entryColor)
            }
        }
    }

    // MARK: - Editor Background

    private var editorBackground: some View {
        ZStack {
            Theme.CelestialColors.void
                .ignoresSafeArea()

            // Subtle gradient based on entry type
            LinearGradient(
                colors: [
                    entryColor.opacity(0.08),
                    entryColor.opacity(0.03),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Paper texture overlay
            Rectangle()
                .fill(.white.opacity(0.02))
                .ignoresSafeArea()
        }
    }

    // MARK: - Entry Type Badge

    private var entryTypeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: entryType.icon)
                .font(.system(size: 14, weight: .semibold))

            Text(entryType.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            Spacer()

            // Word count
            if content.split(separator: " ").count > 0 {
                Text("\(content.split(separator: " ").count) words")
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .foregroundStyle(entryColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(entryColor.opacity(0.15))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(entryColor.opacity(0.3), lineWidth: 0.5)
        }
    }

    // MARK: - AI Prompt Section

    private func aiPromptSection(prompt: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("Today's Prompt")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.CelestialColors.nebulaCore)

            Text(prompt)
                .font(Theme.Typography.cosmosWhisper)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.nebulaCore.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.CelestialColors.nebulaCore.opacity(0.2), lineWidth: 0.5)
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Title (optional)", text: $title)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .tint(entryColor)
    }

    // MARK: - Gratitude Section

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                Text("3 Things You're Grateful For")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(JournalColors.gratitude)

            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: Theme.Spacing.md) {
                    Text("\(index + 1).")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(JournalColors.gratitude.opacity(0.6))
                        .frame(width: 24)

                    TextField("I'm grateful for...", text: Binding(
                        get: { gratitudeItems.indices.contains(index) ? gratitudeItems[index] : "" },
                        set: { newValue in
                            if gratitudeItems.indices.contains(index) {
                                gratitudeItems[index] = newValue
                            }
                        }
                    ))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(JournalColors.gratitude)
                }
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.05))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(JournalColors.gratitude.opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(JournalColors.gratitude.opacity(0.2), lineWidth: 0.5)
        }
    }

    // MARK: - Content Editor

    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Placeholder
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text(entryType.placeholder)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $content)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .tint(entryColor)
                    .focused($isContentFocused)
                    .frame(minHeight: 200)
                    .lineSpacing(6)
            }
        }
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Attachments")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            // Photo Grid
            if !photoAttachments.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(photoAttachments) { attachment in
                        PhotoThumbnailView(attachment: attachment) {
                            removePhoto(attachment)
                        }
                    }
                }
            }

            // Drawing Preview
            if currentDrawing.bounds.size != .zero {
                DrawingPreviewView(drawing: currentDrawing) {
                    showDrawingCanvas = true
                } onDelete: {
                    currentDrawing = PKDrawing()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        }
    }

    // MARK: - Voice Recordings Section

    private var voiceRecordingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                Text("Voice Notes")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.5))

            ForEach(voiceRecordings) { recording in
                VoiceRecordingRow(recording: recording) {
                    removeRecording(recording)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        }
    }

    // MARK: - AI Suggestion Card

    private func aiSuggestionCard(suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("AI Insight")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                Button {
                    aiSuggestion = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .foregroundStyle(Theme.CelestialColors.nebulaCore)

            Text(suggestion)
                .font(Theme.Typography.cosmosWhisperSmall)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.nebulaCore.opacity(0.1))
        }
    }

    // MARK: - Mood Button

    private var moodButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            showMoodPicker = true
        } label: {
            HStack(spacing: 6) {
                if let mood = selectedMood {
                    Text(mood.emoji)
                        .font(.system(size: 20))
                    Text(mood.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Mood")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.white.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating Toolbar

    private var floatingToolbar: some View {
        HStack(spacing: 0) {
            // Photos
            ToolbarButton(icon: "photo", color: entryColor) {
                showPhotosPicker = true
            }

            // Drawing
            ToolbarButton(icon: "pencil.tip", color: entryColor) {
                showDrawingCanvas = true
            }

            // Voice
            ToolbarButton(icon: "mic.fill", color: entryColor) {
                showVoiceRecorder = true
            }

            Spacer()

            // AI Analyze
            ToolbarButton(
                icon: isAnalyzing ? "hourglass" : "sparkles",
                color: Theme.CelestialColors.nebulaCore
            ) {
                analyzeContent()
            }
            .disabled(content.isEmpty || isAnalyzing)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    // MARK: - Actions

    private func setupEntry() {
        if let existingEntry = entry {
            currentEntry = existingEntry
            title = existingEntry.title ?? ""
            content = existingEntry.plainText
            selectedMood = existingEntry.mood
            photoAttachments = existingEntry.getPhotoAttachments()
            voiceRecordings = existingEntry.getVoiceRecordings()
            currentDrawing = existingEntry.getDrawing()

            if existingEntry.entryType == .gratitude {
                gratitudeItems = existingEntry.getGratitudeItems()
                while gratitudeItems.count < 3 {
                    gratitudeItems.append("")
                }
            }
        } else {
            currentEntry = viewModel.createEntry(type: entryType)
        }
    }

    private func saveAndDismiss() {
        guard let entry = currentEntry else {
            dismiss()
            return
        }

        // Update entry
        entry.title = title.isEmpty ? nil : title
        entry.mood = selectedMood

        // Save content
        let attributedString = NSAttributedString(
            string: content,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.white
            ]
        )
        entry.setAttributedString(attributedString)

        // Save gratitude items
        if entryType == .gratitude {
            let filledItems = gratitudeItems.filter { !$0.isEmpty }
            entry.setGratitudeItems(filledItems)
        }

        // Save media
        entry.setPhotoAttachments(photoAttachments)
        entry.setVoiceRecordings(voiceRecordings)
        entry.setDrawing(currentDrawing)

        entry.updatedAt = .now

        do {
            try modelContext.save()
            HapticsService.shared.success()
        } catch {
            print("Failed to save entry: \(error)")
        }

        dismiss()
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let id = UUID()
                let fileName = "\(id).jpg"
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsPath.appendingPathComponent("JournalPhotos/\(fileName)")

                // Create directory if needed
                try? FileManager.default.createDirectory(
                    at: documentsPath.appendingPathComponent("JournalPhotos"),
                    withIntermediateDirectories: true
                )

                // Create thumbnail
                var thumbnailData: Data?
                if let image = UIImage(data: data) {
                    let thumbnailSize = CGSize(width: 200, height: 200)
                    let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
                    let thumbnail = renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
                    }
                    thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
                }

                // Save full image
                do {
                    try data.write(to: filePath)

                    let attachment = PhotoAttachment(
                        id: id,
                        localPath: filePath.path,
                        thumbnailData: thumbnailData,
                        insertionIndex: 0,
                        width: 0,
                        height: 0
                    )

                    await MainActor.run {
                        photoAttachments.append(attachment)
                    }
                } catch {
                    print("Failed to save photo: \(error)")
                }
            }
        }

        selectedPhotos = []
    }

    private func removePhoto(_ attachment: PhotoAttachment) {
        try? FileManager.default.removeItem(atPath: attachment.localPath)
        photoAttachments.removeAll { $0.id == attachment.id }
        HapticsService.shared.lightImpact()
    }

    private func removeRecording(_ recording: VoiceRecording) {
        try? FileManager.default.removeItem(atPath: recording.localPath)
        voiceRecordings.removeAll { $0.id == recording.id }
        HapticsService.shared.lightImpact()
    }

    private func analyzeContent() {
        guard !content.isEmpty else { return }

        isAnalyzing = true
        HapticsService.shared.impact()

        // Simulate AI analysis (replace with actual AI call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnalyzing = false

            let insights = [
                "Your writing shows a reflective mindset today. Consider exploring what triggered these thoughts.",
                "I notice themes of growth and progress in your entry. Keep building on this momentum!",
                "There's a thoughtful quality to your writing. Take time to appreciate your self-awareness.",
                "Your entry suggests you're processing something important. Be patient with yourself.",
                "I sense optimism in your words. This positive energy can carry you through challenges."
            ]

            aiSuggestion = insights.randomElement()
            HapticsService.shared.success()
        }
    }
}

// MARK: - Toolbar Button

struct ToolbarButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let attachment: PhotoAttachment
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnailData = attachment.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.white.opacity(0.3))
                    }
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .background {
                        SwiftUI.Circle()
                            .fill(.black.opacity(0.5))
                    }
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Drawing Preview View

struct DrawingPreviewView: View {
    let drawing: PKDrawing
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Drawing image
            if let image = drawing.image(from: drawing.bounds, scale: 1.0) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        onEdit()
                    }
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .background {
                        SwiftUI.Circle()
                            .fill(.black.opacity(0.5))
                    }
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Voice Recording Row

struct VoiceRecordingRow: View {
    let recording: VoiceRecording
    let onDelete: () -> Void

    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Play/Pause button
            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.aiPurple)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // Duration
                Text(recording.formattedDuration)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                // Transcription preview
                if let transcription = recording.transcription {
                    Text(transcription)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.05))
        }
    }
}

// MARK: - Mood Picker Sheet

struct MoodPickerSheet: View {
    @Binding var selectedMood: JournalMood?
    let entryColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Text("How are you feeling?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, Theme.Spacing.xl)

                HStack(spacing: Theme.Spacing.lg) {
                    ForEach(JournalMood.allCases, id: \.self) { mood in
                        MoodOption(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            HapticsService.shared.selectionFeedback()
                            selectedMood = mood
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Theme.CelestialColors.void)
            .navigationTitle("Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        selectedMood = nil
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

struct MoodOption: View {
    let mood: JournalMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 36))

                Text(mood.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? JournalColors.colorFor(mood: mood).opacity(0.3) : .white.opacity(0.05))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(JournalColors.colorFor(mood: mood).opacity(0.5), lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Drawing Canvas Sheet

struct DrawingCanvasSheet: View {
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            JournalDrawingCanvas(drawing: $drawing)
                .background(.white)
                .navigationTitle("Draw")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Simple Drawing Canvas (Journal-specific)

struct JournalDrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only update if drawings differ
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: JournalDrawingCanvas

        init(_ parent: JournalDrawingCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Voice Recorder Sheet (Placeholder)

struct VoiceRecorderSheet: View {
    @Binding var recordings: [VoiceRecording]
    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Recording visualization
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.aiPurple.opacity(isRecording ? 0.3 : 0.1))
                        .frame(width: 150, height: 150)
                        .scaleEffect(isRecording ? 1.1 : 1)
                        .animation(isRecording ? Theme.Animation.plasmaPulse : .default, value: isRecording)

                    SwiftUI.Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.5), lineWidth: 3)
                        .frame(width: 120, height: 120)

                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.aiPurple)
                }

                // Timer
                Text(formatTime(recordingTime))
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                // Record button
                Button {
                    toggleRecording()
                } label: {
                    ZStack {
                        SwiftUI.Circle()
                            .fill(isRecording ? Theme.Colors.error : Theme.Colors.aiPurple)
                            .frame(width: 80, height: 80)

                        if isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            SwiftUI.Circle()
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(isRecording ? "Tap to stop" : "Tap to record")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()
            }
            .padding()
            .background(Theme.CelestialColors.void)
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func toggleRecording() {
        if isRecording {
            // Stop recording
            isRecording = false
            // TODO: Actually stop recording and save
            let recording = VoiceRecording(
                localPath: "",
                duration: recordingTime,
                transcription: nil
            )
            recordings.append(recording)
            recordingTime = 0
        } else {
            // Start recording
            isRecording = true
            // TODO: Actually start recording
            // For now, just simulate time passing
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if !isRecording {
                    timer.invalidate()
                } else {
                    recordingTime += 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    JournalEditorSheet(
        viewModel: JournalFeedViewModel(),
        entry: nil,
        entryType: .brainDump
    )
    .modelContainer(for: [JournalEntry.self], inMemory: true)
}
