//
//  TaskInputBarV2.swift
//  Veloce
//
//  Floating Island Task Input Bar
//  Revolutionary redesign with NLP, inline chips, and AI-forward interactions
//

import SwiftUI
import Speech

// MARK: - Task Input Bar Mode (State Machine)

enum TaskInputBarMode: Equatable {
    case collapsed          // 56pt, mic + placeholder + plus button
    case focused            // 64pt, chips row visible, keyboard up
    case expanded           // 152pt, action tray open
    case recording          // Voice recording active
    case transcribing       // Converting voice to text
    case aiProcessing       // AI parsing/enhancing
    case templatePicker     // Template selection sheet
    case datePicker         // Inline date picker active
}

// MARK: - Input Task Priority (UI-specific, separate from Task.TaskPriority)

enum InputTaskPriority: Int, CaseIterable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

    var displayStars: String {
        String(repeating: "\u{2605}", count: rawValue)
    }

    var color: Color {
        switch self {
        case .low: return Theme.Colors.aiGreen
        case .medium: return Theme.Colors.aiOrange
        case .high: return Color.red
        }
    }

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - Input Template Category (UI-specific, separate from TaskTemplate.TemplateCategory)

enum InputTemplateCategory: String, CaseIterable, Identifiable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case errands = "Errands"
    case learning = "Learning"
    case creative = "Creative"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .errands: return "cart.fill"
        case .learning: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return Theme.Colors.aiBlue
        case .personal: return Theme.Colors.aiPurple
        case .health: return Theme.Colors.aiGreen
        case .errands: return Theme.Colors.aiOrange
        case .learning: return Theme.Colors.aiCyan
        case .creative: return Theme.Colors.aiPink
        case .custom: return Theme.CelestialColors.nebulaCore
        }
    }
}

// MARK: - Task Input Data (Output Model)

struct TaskInputData {
    var title: String
    var priority: InputTaskPriority = .medium
    var scheduledDate: Date?
    var scheduledTime: Date?
    var categories: Set<InputTemplateCategory> = []
    var estimatedMinutes: Int?
    var recurringType: String?
    var subtasks: [String]?
    var fromTemplate: QuickAddTemplate?
    var aiEnhanced: Bool = false

    /// Combined date and time
    var combinedDateTime: Date? {
        guard let date = scheduledDate else { return nil }
        guard let time = scheduledTime else { return date }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: date
        )
    }
}

// MARK: - Floating Island Metrics

private enum FloatingIslandMetrics {
    // Heights
    static let collapsedHeight: CGFloat = 56
    static let focusedHeight: CGFloat = 64
    static let expandedHeight: CGFloat = 152
    static let chipsRowHeight: CGFloat = 40
    static let maxExpandedHeight: CGFloat = 180

    // Dimensions
    static let collapsedHorizontalMargin: CGFloat = 16
    static let focusedHorizontalMargin: CGFloat = 12
    static let collapsedCornerRadius: CGFloat = 28
    static let focusedCornerRadius: CGFloat = 32
    static let bottomSafeAreaMargin: CGFloat = 12

    // Buttons
    static let buttonSize: CGFloat = 38
    static let sendButtonSize: CGFloat = 38
    static let iconSize: CGFloat = 16
    static let micIconSize: CGFloat = 18
    static let aiIconSize: CGFloat = 14

    // Spacing
    static let elementSpacing: CGFloat = 12
    static let chipSpacing: CGFloat = 8
}

// MARK: - Task Input Bar V2

struct TaskInputBarV2: View {
    // MARK: - Bindings
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    // MARK: - Callbacks
    var onSubmit: (TaskInputData) -> Void
    var onVoiceInput: (() -> Void)? = nil

    // MARK: - State Machine
    @State private var mode: TaskInputBarMode = .collapsed

    // MARK: - Task Input State
    @State private var priority: InputTaskPriority = .medium
    @State private var selectedDate: Date?
    @State private var selectedTime: Date?
    @State private var categories: Set<InputTemplateCategory> = []
    @State private var estimatedMinutes: Int?

    // MARK: - NLP Detection State
    @State private var nlpDetections: [NLPDetection] = []
    @State private var nlpParseTask: Task<Void, Never>?

    // MARK: - Voice Recording State
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var recordingPulse: CGFloat = 1.0
    @State private var audioLevel: Float = 0
    @State private var currentRecordingURL: URL?
    @State private var voiceError: String?
    @State private var showVoiceError = false
    @State private var audioLevelTimer: Timer?

    // MARK: - AI State
    @State private var aiModeEnabled = false
    @State private var isAIProcessing = false
    @State private var aiDotPhase: Int = 0
    @State private var showAITray = false
    @State private var isAIEnhancing = false
    @State private var aiEnhanceError: String?
    @State private var showAIError = false

    // MARK: - Category Badge State
    @State private var showCategoryBadge = false
    @State private var categoryText: String = ""

    // MARK: - Sheet State
    @State private var showActionTray = false
    @State private var showTemplatePicker = false
    @State private var showDatePicker = false
    @State private var showCategoryPicker = false
    @State private var showAISheet = false

    // MARK: - Animation State
    @State private var sendPulse: CGFloat = 1.0
    @State private var borderRotation: Double = 0
    @State private var sparkleRotation: Double = 0

    // MARK: - Services
    private var voiceService: VoiceRecordingService { VoiceRecordingService.shared }
    private var aiService: AIService { AIService.shared }

    // MARK: - Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - iOS 26 Namespaces for Morphing
    @Namespace private var inputBarNamespace
    @Namespace private var sheetNamespace
    @Namespace private var glassNamespace

    // MARK: - Computed Properties

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var effectiveMode: TaskInputBarMode {
        if isRecording { return .recording }
        if isTranscribing { return .transcribing }
        if isAIProcessing { return .aiProcessing }
        if showActionTray { return .expanded }
        if isFocused.wrappedValue { return .focused }
        return .collapsed
    }

    private var currentHeight: CGFloat {
        switch effectiveMode {
        case .collapsed:
            return FloatingIslandMetrics.collapsedHeight
        case .focused, .recording, .transcribing, .aiProcessing:
            return FloatingIslandMetrics.focusedHeight
        case .expanded:
            return FloatingIslandMetrics.expandedHeight
        case .templatePicker, .datePicker:
            return FloatingIslandMetrics.focusedHeight
        }
    }

    private var currentCornerRadius: CGFloat {
        effectiveMode == .collapsed
            ? FloatingIslandMetrics.collapsedCornerRadius
            : FloatingIslandMetrics.focusedCornerRadius
    }

    private var currentHorizontalMargin: CGFloat {
        effectiveMode == .collapsed
            ? FloatingIslandMetrics.collapsedHorizontalMargin
            : FloatingIslandMetrics.focusedHorizontalMargin
    }

    private var showChipsRow: Bool {
        isFocused.wrappedValue || selectedDate != nil || !categories.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Category badge (shows after AI processing)
            if showCategoryBadge {
                categoryBadgeView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .padding(.bottom, 8)
            }

            // Chips row (visible when focused or has selections)
            if showChipsRow {
                chipsRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }

            // Main floating island container
            floatingIslandContainer
        }
        .animation(Theme.Animation.springBouncy, value: effectiveMode)
        .animation(Theme.Animation.springBouncy, value: showCategoryBadge)
        .animation(Theme.Animation.springBouncy, value: showChipsRow)
        .animation(Theme.Animation.spring, value: canSend)

        // Sheets
        .sheet(isPresented: $showTemplatePicker) {
            templatePickerSheet
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showAISheet) {
            aiEnhanceSheet
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet
        }

        // Alerts
        .alert("Voice Input Error", isPresented: $showVoiceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(voiceError ?? "An unknown error occurred")
        }
        .alert("AI Error", isPresented: $showAIError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(aiEnhanceError ?? "Failed to process with AI")
        }

        // Lifecycle
        .onAppear {
            startAmbientAnimations()
        }
        .onDisappear {
            cleanupOnDisappear()
        }
        .onChange(of: text) { _, newValue in
            parseTextForNLP(newValue)
        }
    }

    // MARK: - Floating Island Container

    private var floatingIslandContainer: some View {
        VStack(spacing: 0) {
            // Main input row
            mainInputRow

            // Action tray (when expanded)
            if showActionTray {
                actionTrayContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, FloatingIslandMetrics.collapsedHorizontalMargin)
        .padding(.vertical, isFocused.wrappedValue ? 14 : 8)
        .frame(minHeight: currentHeight)
        .background { floatingIslandBackground }
        .overlay { floatingIslandBorder }
        .floatingIslandShadow(mode: effectiveMode, canSend: canSend)
        .overlay {
            if isAIProcessing {
                aiProcessingOverlay
            }
        }
        .padding(.horizontal, currentHorizontalMargin)
        .matchedGeometryEffect(id: "floatingIsland", in: inputBarNamespace)
    }

    // MARK: - Main Input Row

    private var mainInputRow: some View {
        // iOS 26: GlassEffectContainer for optimized morphing between glass elements
        GlassEffectContainer(spacing: FloatingIslandMetrics.elementSpacing) {
            HStack(spacing: FloatingIslandMetrics.elementSpacing) {
                // Voice input button (left)
                voiceInputButton

                // Text field (center, flexible)
                expandingTextField

                // Right controls
                HStack(spacing: 8) {
                    // AI sparkles (visible when focused)
                    if isFocused.wrappedValue {
                        aiSparklesButton
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Send or Plus button
                    if canSend {
                        sendButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: - Floating Island Background

    private var floatingIslandBackground: some View {
        ZStack {
            // iOS 26 Liquid Glass
            Capsule()
                .fill(.clear)
                .adaptiveGlassCapsule()

            // Focused state tint overlay
            if isFocused.wrappedValue {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.04),
                                Theme.Colors.aiBlue.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }

            // Recording state red tint
            if isRecording {
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.red.opacity(0.08),
                                Color.clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Floating Island Border

    @ViewBuilder
    private var floatingIslandBorder: some View {
        if isRecording && !reduceMotion {
            // Animated holographic border when recording
            Capsule()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.red.opacity(0.7),
                            Theme.Colors.aiPink.opacity(0.5),
                            Color.red.opacity(0.4),
                            Theme.Colors.aiPurple.opacity(0.5),
                            Color.red.opacity(0.7)
                        ],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: 2
                )
                .blur(radius: 0.5)
        } else if isFocused.wrappedValue {
            // Focus gradient border
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.5),
                            Theme.Colors.aiBlue.opacity(0.3),
                            Theme.Colors.aiCyan.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        } else {
            // Default subtle border
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }

    // MARK: - Voice Input Button

    private var voiceInputButton: some View {
        Button {
            HapticsService.shared.impact()
            toggleVoiceRecording()
        } label: {
            ZStack {
                // Recording pulse rings
                if isRecording && !reduceMotion {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(Color.red.opacity(0.3 - Double(ring) * 0.1), lineWidth: 2)
                            .frame(
                                width: FloatingIslandMetrics.buttonSize + CGFloat(ring) * 12,
                                height: FloatingIslandMetrics.buttonSize + CGFloat(ring) * 12
                            )
                            .scaleEffect(recordingPulse)
                            .opacity(Double(3 - ring) / 3)
                    }
                }

                // Transcribing pulse
                if isTranscribing && !reduceMotion {
                    Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 2)
                        .frame(width: FloatingIslandMetrics.buttonSize + 8, height: FloatingIslandMetrics.buttonSize + 8)
                        .scaleEffect(recordingPulse)
                }

                // Button background
                voiceButtonBackground

                // Audio level indicator
                if isRecording {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: FloatingIslandMetrics.buttonSize, height: FloatingIslandMetrics.buttonSize)
                        .scaleEffect(0.3 + CGFloat(audioLevel) * 0.7)
                }

                // Icon
                voiceButtonIcon
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(isTranscribing)
        .accessibilityLabel(voiceButtonAccessibilityLabel)
        // iOS 26: Glass effect with morphing ID
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("voiceInput", in: glassNamespace)
    }

    @ViewBuilder
    private var voiceButtonBackground: some View {
        if isRecording {
            Circle()
                .fill(Color.red)
                .frame(width: FloatingIslandMetrics.buttonSize, height: FloatingIslandMetrics.buttonSize)
        } else if isTranscribing {
            Circle()
                .fill(Theme.Colors.aiPurple.opacity(0.2))
                .frame(width: FloatingIslandMetrics.buttonSize, height: FloatingIslandMetrics.buttonSize)
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: FloatingIslandMetrics.buttonSize, height: FloatingIslandMetrics.buttonSize)
        }
    }

    @ViewBuilder
    private var voiceButtonIcon: some View {
        if isTranscribing {
            Image(systemName: "waveform")
                .font(.system(size: FloatingIslandMetrics.micIconSize, weight: .medium))
                .foregroundStyle(Theme.Colors.aiPurple)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
        } else {
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: FloatingIslandMetrics.micIconSize, weight: .medium))
                .foregroundStyle(isRecording ? .white : .secondary)
                .scaleEffect(isRecording ? 0.85 : 1.0)
        }
    }

    private var voiceButtonAccessibilityLabel: String {
        if isTranscribing {
            return "Transcribing audio"
        } else if isRecording {
            return "Stop recording"
        } else {
            return "Voice input"
        }
    }

    // MARK: - Expanding Text Field

    private var expandingTextField: some View {
        TextField("", text: $text, prompt: placeholderText, axis: .vertical)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.primary)
            .lineLimit(isFocused.wrappedValue ? 1...6 : 1...2)
            .focused(isFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    submitTask()
                }
            }
            .tint(Theme.Colors.aiPurple)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isFocused.wrappedValue = false
                        HapticsService.shared.lightImpact()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
    }

    private var placeholderText: Text {
        Text("What's on your mind?")
            .font(.system(size: 16, weight: .light))
            .italic()
            .foregroundStyle(.secondary.opacity(0.6))
    }

    // MARK: - AI Sparkles Button

    private var aiSparklesButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            if canSend {
                showAISheet = true
            } else {
                withAnimation(Theme.Animation.springBouncy) {
                    aiModeEnabled.toggle()
                }
                if aiModeEnabled {
                    HapticsService.shared.success()
                }
            }
        } label: {
            ZStack {
                // Glow when enabled
                if aiModeEnabled || isAIEnhancing {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.4),
                                    Theme.Colors.aiCyan.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 52, height: 52)
                        .blur(radius: 6)
                        .scaleEffect(isAIEnhancing ? 1.2 : 1.0)
                }

                // Button background
                Circle()
                    .fill(
                        aiModeEnabled
                            ? LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiCyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: FloatingIslandMetrics.buttonSize - 4, height: FloatingIslandMetrics.buttonSize - 4)
                    .overlay {
                        if aiModeEnabled && !reduceMotion {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            Theme.Colors.aiPurple,
                                            Theme.Colors.aiCyan,
                                            Theme.Colors.aiPink,
                                            Theme.Colors.aiPurple
                                        ],
                                        center: .center,
                                        angle: .degrees(sparkleRotation)
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }

                // Icon
                if isAIEnhancing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.aiPurple)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: FloatingIslandMetrics.aiIconSize, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: aiModeEnabled
                                    ? [Theme.Colors.aiPurple, Theme.Colors.aiCyan, Theme.Colors.aiPink]
                                    : [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: aiModeEnabled)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(isAIEnhancing)
        .accessibilityLabel(canSend ? "Enhance with AI" : (aiModeEnabled ? "AI mode enabled" : "Enable AI mode"))
        // iOS 26: Glass effect with morphing ID
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("aiSparkles", in: glassNamespace)
        // iOS 26: Sheet morphing source
        .matchedTransitionSource(id: "aiSheet", in: sheetNamespace)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    sparkleRotation = 360
                }
            }
        }
    }

    // MARK: - Plus Button (Action Tray Trigger)

    private var plusButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            if text.isEmpty {
                showTemplatePicker = true
            } else {
                withAnimation(Theme.Animation.springBouncy) {
                    showActionTray.toggle()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: FloatingIslandMetrics.buttonSize, height: FloatingIslandMetrics.buttonSize)

                Image(systemName: showActionTray ? "xmark" : "plus")
                    .font(.system(size: FloatingIslandMetrics.iconSize, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showActionTray ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(showActionTray ? "Close menu" : "Quick add")
        // iOS 26: Glass effect with morphing ID
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("quickAdd", in: glassNamespace)
        // iOS 26: Sheet morphing source for template picker
        .matchedTransitionSource(id: "templatePicker", in: sheetNamespace)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            submitTask()
        } label: {
            ZStack {
                // Ambient glow
                if !reduceMotion {
                    Circle()
                        .fill(Theme.AdaptiveColors.aiPrimary.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                        .scaleEffect(sendPulse)
                }

                // Main button with iOS 26 glass prominent styling
                Circle()
                    .fill(Theme.AdaptiveColors.aiGradient)
                    .frame(width: FloatingIslandMetrics.sendButtonSize, height: FloatingIslandMetrics.sendButtonSize)
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 16
                                )
                            )
                    }

                // Arrow icon
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(OrbButtonStyle())
        .accessibilityLabel("Send task")
        // iOS 26: Glass effect with morphing ID for send button
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID("sendButton", in: glassNamespace)
    }

    // MARK: - Chips Row

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // iOS 26: GlassEffectContainer for chip morphing
            GlassEffectContainer(spacing: FloatingIslandMetrics.chipSpacing) {
                HStack(spacing: FloatingIslandMetrics.chipSpacing) {
                    // Priority chip
                    PriorityChipView(priority: $priority)
                        .glassEffectID("priorityChip", in: glassNamespace)

                    // Date chip
                    if let date = selectedDate {
                        DateChipView(
                            date: date,
                            time: selectedTime,
                            onTap: { showDatePicker = true },
                            onRemove: {
                                withAnimation(Theme.Animation.spring) {
                                    selectedDate = nil
                                    selectedTime = nil
                                }
                                HapticsService.shared.lightImpact()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .glassEffectID("dateChip", in: glassNamespace)
                        // iOS 26: Sheet morphing source
                        .matchedTransitionSource(id: "datePicker", in: sheetNamespace)
                    } else if isFocused.wrappedValue {
                        AddChipButton(icon: "calendar", label: "Date") {
                            showDatePicker = true
                        }
                        .glassEffectID("addDateChip", in: glassNamespace)
                        // iOS 26: Sheet morphing source
                        .matchedTransitionSource(id: "datePicker", in: sheetNamespace)
                    }

                    // Category chips
                    ForEach(Array(categories), id: \.self) { category in
                        CategoryChipView(category: category) {
                            withAnimation(Theme.Animation.spring) {
                                categories.remove(category)
                            }
                            HapticsService.shared.lightImpact()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .glassEffectID("category_\(category.id)", in: glassNamespace)
                    }

                    // Add category button
                    if isFocused.wrappedValue && categories.count < 3 {
                        AddChipButton(icon: "tag", label: "Tag") {
                            showCategoryPicker = true
                        }
                        .glassEffectID("addCategoryChip", in: glassNamespace)
                        // iOS 26: Sheet morphing source
                        .matchedTransitionSource(id: "categoryPicker", in: sheetNamespace)
                    }

                    // Duration chip (if estimated)
                    if let minutes = estimatedMinutes {
                        DurationChipView(minutes: minutes) {
                            withAnimation(Theme.Animation.spring) {
                                estimatedMinutes = nil
                            }
                            HapticsService.shared.lightImpact()
                        }
                        .transition(.scale.combined(with: .opacity))
                        .glassEffectID("durationChip", in: glassNamespace)
                    }
                }
            }
            .padding(.horizontal, currentHorizontalMargin + FloatingIslandMetrics.collapsedHorizontalMargin)
        }
        .frame(height: FloatingIslandMetrics.chipsRowHeight)
    }

    // MARK: - Action Tray Content

    private var actionTrayContent: some View {
        // iOS 26: GlassEffectContainer for action tray morphing
        GlassEffectContainer(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                InputV2ActionTrayButton(item: .templates, action: { showTemplatePicker = true })
                    .glassEffectID("actionTemplates", in: glassNamespace)
                    .matchedTransitionSource(id: "templatePicker", in: sheetNamespace)

                InputV2ActionTrayButton(item: .voice, action: { toggleVoiceRecording() })
                    .glassEffectID("actionVoice", in: glassNamespace)

                InputV2ActionTrayButton(item: .calendar, action: { showDatePicker = true })
                    .glassEffectID("actionCalendar", in: glassNamespace)
                    .matchedTransitionSource(id: "datePicker", in: sheetNamespace)

                InputV2ActionTrayButton(item: .category, action: { showCategoryPicker = true })
                    .glassEffectID("actionCategory", in: glassNamespace)
                    .matchedTransitionSource(id: "categoryPicker", in: sheetNamespace)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - AI Processing Overlay

    private var aiProcessingOverlay: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.08),
                        Theme.Colors.aiCyan.opacity(0.05),
                        Theme.Colors.aiPurple.opacity(0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: 8, height: 8)
                            .opacity(aiDotPhase == index ? 1.0 : 0.3)
                            .scaleEffect(aiDotPhase == index ? 1.2 : 0.8)
                    }
                }
            }
            .allowsHitTesting(false)
    }

    // MARK: - Category Badge

    private var categoryBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))

            Text(categoryText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.aiPurple)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.12))
                .overlay {
                    Capsule()
                        .stroke(Theme.Colors.aiPurple.opacity(0.25), lineWidth: 0.5)
                }
        }
    }

    // MARK: - Sheet Views

    private var templatePickerSheet: some View {
        QuickAddSheet(
            templates: .constant(QuickAddTemplate.defaults),
            onSelect: { template in
                text = template.title
                showTemplatePicker = false
                HapticsService.shared.selectionFeedback()
            },
            onAddCustom: {
                showTemplatePicker = false
                isFocused.wrappedValue = true
            }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        // iOS 26: Morphing transition from source button
        .navigationTransition(.zoom(sourceID: "templatePicker", in: sheetNamespace))
    }

    private var datePickerSheet: some View {
        InlineDatePickerSheet(
            selectedDate: $selectedDate,
            selectedTime: $selectedTime,
            onDismiss: { showDatePicker = false }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        // iOS 26: Morphing transition from date chip
        .navigationTransition(.zoom(sourceID: "datePicker", in: sheetNamespace))
    }

    private var aiEnhanceSheet: some View {
        AIEnhanceSheet(
            text: $text,
            isProcessing: $isAIEnhancing,
            onEnhance: { action in
                performAIAction(action)
            },
            onDismiss: {
                showAISheet = false
            }
        )
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        // iOS 26: Morphing transition from AI sparkles button
        .navigationTransition(.zoom(sourceID: "aiSheet", in: sheetNamespace))
    }

    private var categoryPickerSheet: some View {
        CategoryPickerSheet(
            selectedCategories: $categories,
            onDismiss: { showCategoryPicker = false }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        // iOS 26: Morphing transition from category chip
        .navigationTransition(.zoom(sourceID: "categoryPicker", in: sheetNamespace))
    }
}

// MARK: - Actions Extension

extension TaskInputBarV2 {

    // MARK: - Voice Recording

    private func toggleVoiceRecording() {
        if isRecording {
            stopVoiceRecording()
        } else {
            startVoiceRecording()
        }
    }

    private func startVoiceRecording() {
        Task {
            do {
                let url = try await voiceService.startRecording()
                currentRecordingURL = url

                await MainActor.run {
                    isRecording = true
                    onVoiceInput?()

                    if !reduceMotion {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            recordingPulse = 1.15
                        }
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            borderRotation = 360
                        }
                    }

                    startAudioLevelMonitoring()
                }
            } catch {
                await MainActor.run {
                    voiceError = error.localizedDescription
                    showVoiceError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func stopVoiceRecording() {
        Task {
            do {
                let recording = try await voiceService.stopRecording()

                await MainActor.run {
                    isRecording = false
                    stopAudioLevelMonitoring()
                    recordingPulse = 1.0
                    borderRotation = 0
                    audioLevel = 0
                    isTranscribing = true

                    if !reduceMotion {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            recordingPulse = 1.1
                        }
                    }
                }

                let audioURL = URL(fileURLWithPath: recording.localPath)
                let transcription = try await voiceService.transcribe(audioURL: audioURL)

                await MainActor.run {
                    isTranscribing = false
                    recordingPulse = 1.0

                    if text.isEmpty {
                        text = transcription
                    } else {
                        text += " " + transcription
                    }

                    isFocused.wrappedValue = true
                    HapticsService.shared.success()
                    voiceService.deleteRecording(at: recording.localPath)
                }
            } catch {
                await MainActor.run {
                    isRecording = false
                    isTranscribing = false
                    recordingPulse = 1.0
                    borderRotation = 0
                    audioLevel = 0
                    stopAudioLevelMonitoring()

                    voiceError = error.localizedDescription
                    showVoiceError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                self.audioLevel = self.voiceService.audioLevel
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }

    // MARK: - Task Submission

    private func submitTask() {
        guard canSend else { return }

        let taskText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticsService.shared.impact()

        startAIProcessing()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let inputData = TaskInputData(
                title: taskText,
                priority: priority,
                scheduledDate: selectedDate,
                scheduledTime: selectedTime,
                categories: categories,
                estimatedMinutes: estimatedMinutes,
                aiEnhanced: aiModeEnabled
            )

            onSubmit(inputData)
            resetInputState()
            stopAIProcessing()
            showCategoryResult()
        }
    }

    private func resetInputState() {
        text = ""
        priority = .medium
        selectedDate = nil
        selectedTime = nil
        categories = []
        estimatedMinutes = nil
        nlpDetections = []
    }

    // MARK: - AI Processing

    private func startAIProcessing() {
        isAIProcessing = true
        aiDotPhase = 0

        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if !isAIProcessing {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                aiDotPhase = (aiDotPhase + 1) % 3
            }
        }

        HapticsService.shared.aiProcessingStart()
    }

    private func stopAIProcessing() {
        isAIProcessing = false
        HapticsService.shared.aiProcessingComplete()
    }

    private func showCategoryResult() {
        let detectedCategories = ["Work", "Personal", "Health", "Learning", "Creative"]
        categoryText = detectedCategories.randomElement() ?? "Task"

        withAnimation(Theme.Animation.springBouncy) {
            showCategoryBadge = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(Theme.Animation.spring) {
                showCategoryBadge = false
            }
        }
    }

    private func performAIAction(_ action: AIEnhanceAction) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isAIEnhancing = true
        showAISheet = false

        Task {
            do {
                switch action {
                case .enhance:
                    let enhanced = try await enhanceTaskText(text)
                    await MainActor.run {
                        text = enhanced
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .estimateTime:
                    let minutes = try await aiService.estimateTime(for: text)
                    await MainActor.run {
                        estimatedMinutes = minutes
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .categorize:
                    let priorityResult = try await aiService.assessPriority(for: text)
                    await MainActor.run {
                        categoryText = priorityResult.label
                        isAIEnhancing = false
                        withAnimation(Theme.Animation.springBouncy) {
                            showCategoryBadge = true
                        }
                        HapticsService.shared.success()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(Theme.Animation.spring) {
                                showCategoryBadge = false
                            }
                        }
                    }

                case .breakDown:
                    let subTasks = try await generateSubTasks(for: text)
                    await MainActor.run {
                        if !subTasks.isEmpty {
                            text = subTasks.map { "• \($0)" }.joined(separator: "\n")
                        }
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .smartSchedule:
                    let suggestedTime = try await suggestOptimalTime(for: text)
                    await MainActor.run {
                        selectedDate = suggestedTime.date
                        selectedTime = suggestedTime.time
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .findSimilar:
                    // Find similar tasks - for now, show a notification
                    await MainActor.run {
                        categoryText = "Finding similar..."
                        isAIEnhancing = false
                        withAnimation(Theme.Animation.springBouncy) {
                            showCategoryBadge = true
                        }
                        HapticsService.shared.success()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(Theme.Animation.spring) {
                                showCategoryBadge = false
                            }
                        }
                    }

                case .autoTag:
                    let suggestedCategories = try await suggestCategories(for: text)
                    await MainActor.run {
                        for category in suggestedCategories {
                            withAnimation(Theme.Animation.springBouncy) {
                                categories.insert(category)
                            }
                        }
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .summarize:
                    let summarized = try await summarizeTask(text)
                    await MainActor.run {
                        text = summarized
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }
                }
            } catch {
                await MainActor.run {
                    isAIEnhancing = false
                    aiEnhanceError = error.localizedDescription
                    showAIError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func enhanceTaskText(_ original: String) async throws -> String {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Rewrite this task to be clearer and more actionable. Keep it concise (1 sentence max).
        Original: \(original)

        Respond with ONLY the improved task text, nothing else.
        """

        let perplexity = PerplexityService.shared
        let (response, _) = try await perplexity.generateText(
            prompt: prompt,
            temperature: 0.5,
            maxTokens: 100
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateSubTasks(for taskTitle: String) async throws -> [String] {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Break down this task into 3-5 simple sub-tasks.
        Task: \(taskTitle)

        Respond with ONLY a JSON array of strings, like: ["Step 1", "Step 2", "Step 3"]
        """

        let perplexity = PerplexityService.shared
        let jsonResponse = try await perplexity.generateJSON(prompt: prompt, temperature: 0.4)

        guard let data = jsonResponse.data(using: .utf8),
              let steps = try? JSONDecoder().decode([String].self, from: data) else {
            return [taskTitle]
        }

        return steps
    }

    // MARK: - New AI Actions

    private struct SuggestedSchedule {
        let date: Date
        let time: Date?
    }

    private func suggestOptimalTime(for taskTitle: String) async throws -> SuggestedSchedule {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Based on this task, suggest an optimal date and time to complete it.
        Task: \(taskTitle)

        Consider:
        - Urgency implied by the text
        - Common scheduling patterns
        - Work-life balance

        Respond with ONLY a JSON object like: {"date": "2024-01-15", "time": "14:00"}
        Use ISO 8601 date format (YYYY-MM-DD) and 24-hour time format (HH:mm).
        If no specific time is needed, omit the time field.
        """

        let perplexity = PerplexityService.shared
        let jsonResponse = try await perplexity.generateJSON(prompt: prompt, temperature: 0.5)

        struct ScheduleResponse: Decodable {
            let date: String
            let time: String?
        }

        guard let data = jsonResponse.data(using: .utf8),
              let response = try? JSONDecoder().decode(ScheduleResponse.self, from: data) else {
            // Fallback: suggest tomorrow morning
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return SuggestedSchedule(date: tomorrow, time: nil)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        guard let date = dateFormatter.date(from: response.date) else {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return SuggestedSchedule(date: tomorrow, time: nil)
        }

        let time = response.time.flatMap { timeFormatter.date(from: $0) }
        return SuggestedSchedule(date: date, time: time)
    }

    private func suggestCategories(for taskTitle: String) async throws -> [InputTemplateCategory] {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let categoryNames = InputTemplateCategory.allCases.map { $0.rawValue }
        let prompt = """
        Categorize this task into 1-2 of these categories: \(categoryNames.joined(separator: ", "))
        Task: \(taskTitle)

        Respond with ONLY a JSON array of category names, like: ["Work", "Learning"]
        """

        let perplexity = PerplexityService.shared
        let jsonResponse = try await perplexity.generateJSON(prompt: prompt, temperature: 0.3)

        guard let data = jsonResponse.data(using: .utf8),
              let categoryStrings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return categoryStrings.compactMap { name in
            InputTemplateCategory.allCases.first { $0.rawValue.lowercased() == name.lowercased() }
        }
    }

    private func summarizeTask(_ original: String) async throws -> String {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Make this task description more concise while keeping all important details.
        Keep it to 1 short sentence (max 10 words).
        Original: \(original)

        Respond with ONLY the summarized task text, nothing else.
        """

        let perplexity = PerplexityService.shared
        let (response, _) = try await perplexity.generateText(
            prompt: prompt,
            temperature: 0.4,
            maxTokens: 50
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - NLP Parsing

    private func parseTextForNLP(_ text: String) {
        nlpParseTask?.cancel()

        nlpParseTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
            guard !Task.isCancelled else { return }

            let detections = TaskNLPService.parse(text)

            await MainActor.run {
                // Auto-set date if detected with high confidence
                for detection in detections {
                    switch detection.type {
                    case .date:
                        if detection.confidence > 0.8, selectedDate == nil {
                            if let date = detection.value as? Date {
                                withAnimation(Theme.Animation.springBouncy) {
                                    selectedDate = date
                                }
                                HapticsService.shared.selectionFeedback()
                            }
                        }
                    case .time:
                        if detection.confidence > 0.8 {
                            if let time = detection.value as? Date {
                                withAnimation(Theme.Animation.springBouncy) {
                                    selectedTime = time
                                }
                                HapticsService.shared.selectionFeedback()
                            }
                        }
                    case .priority:
                        if detection.confidence > 0.9 {
                            if let p = detection.value as? InputTaskPriority {
                                withAnimation(Theme.Animation.spring) {
                                    priority = p
                                }
                            }
                        }
                    case .category:
                        if detection.confidence > 0.9 {
                            if let cat = detection.value as? InputTemplateCategory {
                                withAnimation(Theme.Animation.spring) {
                                    categories.insert(cat)
                                }
                            }
                        }
                    case .duration:
                        if detection.confidence > 0.9 {
                            if let mins = detection.value as? Int {
                                withAnimation(Theme.Animation.spring) {
                                    estimatedMinutes = mins
                                }
                            }
                        }
                    }
                }

                nlpDetections = detections
            }
        }
    }

    // MARK: - Lifecycle

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            sendPulse = 1.06
        }
    }

    private func cleanupOnDisappear() {
        if isRecording {
            voiceService.cancelRecording()
            isRecording = false
        }
        stopAudioLevelMonitoring()
        nlpParseTask?.cancel()
    }
}

// MARK: - Supporting Views

// MARK: NLP Detection

struct NLPDetection {
    enum DetectionType {
        case date, time, priority, category, duration
    }

    let type: DetectionType
    let range: Range<String.Index>
    let value: Any
    let originalText: String
    let confidence: Double
}

// MARK: Task NLP Service (Simplified)

enum TaskNLPService {
    static func parse(_ text: String) -> [NLPDetection] {
        var detections: [NLPDetection] = []
        let lowercased = text.lowercased()

        // Date patterns
        if lowercased.contains("today") {
            if let range = lowercased.range(of: "today") {
                detections.append(NLPDetection(
                    type: .date,
                    range: range,
                    value: Date(),
                    originalText: "today",
                    confidence: 0.95
                ))
            }
        }

        if lowercased.contains("tomorrow") {
            if let range = lowercased.range(of: "tomorrow") {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                detections.append(NLPDetection(
                    type: .date,
                    range: range,
                    value: tomorrow,
                    originalText: "tomorrow",
                    confidence: 0.95
                ))
            }
        }

        if lowercased.contains("next week") {
            if let range = lowercased.range(of: "next week") {
                let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
                detections.append(NLPDetection(
                    type: .date,
                    range: range,
                    value: nextWeek,
                    originalText: "next week",
                    confidence: 0.9
                ))
            }
        }

        // Time patterns (simple regex)
        let timePattern = try? NSRegularExpression(pattern: "at\\s+(\\d{1,2})(:\\d{2})?\\s*(am|pm)?", options: .caseInsensitive)
        if let match = timePattern?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let matchedString = String(text[Range(match.range, in: text)!])
            // Parse time (simplified)
            var hour = 9 // default
            if let hourMatch = try? NSRegularExpression(pattern: "(\\d{1,2})", options: []).firstMatch(in: matchedString, range: NSRange(matchedString.startIndex..., in: matchedString)),
               let range = Range(hourMatch.range(at: 1), in: matchedString) {
                hour = Int(matchedString[range]) ?? 9
            }
            if matchedString.lowercased().contains("pm") && hour < 12 {
                hour += 12
            }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = 0

            if let time = Calendar.current.date(from: components),
               let range = Range(match.range, in: text) {
                detections.append(NLPDetection(
                    type: .time,
                    range: range,
                    value: time,
                    originalText: matchedString,
                    confidence: 0.85
                ))
            }
        }

        // Priority patterns
        if text.hasSuffix("!!!") {
            if let range = text.range(of: "!!!") {
                detections.append(NLPDetection(
                    type: .priority,
                    range: range,
                    value: InputTaskPriority.high,
                    originalText: "!!!",
                    confidence: 1.0
                ))
            }
        } else if text.hasSuffix("!!") {
            if let range = text.range(of: "!!") {
                detections.append(NLPDetection(
                    type: .priority,
                    range: range,
                    value: InputTaskPriority.medium,
                    originalText: "!!",
                    confidence: 1.0
                ))
            }
        } else if text.hasSuffix("!") && !text.hasSuffix("!!") {
            if let range = text.range(of: "!") {
                detections.append(NLPDetection(
                    type: .priority,
                    range: range,
                    value: InputTaskPriority.low,
                    originalText: "!",
                    confidence: 0.9
                ))
            }
        }

        // Category patterns (#work, #personal, etc.)
        let categoryPatterns: [(String, InputTemplateCategory)] = [
            ("#work", .work),
            ("#personal", .personal),
            ("#health", .health),
            ("#errands", .errands),
            ("#learning", .learning),
            ("#creative", .creative)
        ]

        for (pattern, category) in categoryPatterns {
            if lowercased.contains(pattern) {
                if let range = lowercased.range(of: pattern) {
                    detections.append(NLPDetection(
                        type: .category,
                        range: range,
                        value: category,
                        originalText: pattern,
                        confidence: 0.95
                    ))
                }
            }
        }

        // Duration patterns (e.g., "30min", "1h", "for 2 hours")
        let durationPattern = try? NSRegularExpression(pattern: "(\\d+)\\s*(min|m|hour|h|hr)s?", options: .caseInsensitive)
        if let match = durationPattern?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let matchedString = String(text[range])
            var minutes = 30 // default

            if let numberMatch = try? NSRegularExpression(pattern: "(\\d+)", options: []).firstMatch(in: matchedString, range: NSRange(matchedString.startIndex..., in: matchedString)),
               let numRange = Range(numberMatch.range(at: 1), in: matchedString) {
                let number = Int(matchedString[numRange]) ?? 30
                if matchedString.lowercased().contains("h") {
                    minutes = number * 60
                } else {
                    minutes = number
                }
            }

            detections.append(NLPDetection(
                type: .duration,
                range: range,
                value: minutes,
                originalText: matchedString,
                confidence: 0.9
            ))
        }

        return detections
    }
}

// MARK: - Floating Island Shadow Modifier

extension View {
    func floatingIslandShadow(mode: TaskInputBarMode, canSend: Bool) -> some View {
        self
            // Layer 1: Deep void shadow
            .shadow(
                color: Color.black.opacity(0.50),
                radius: 40,
                y: 20
            )
            // Layer 2: Nebula glow
            .shadow(
                color: canSend ? Theme.Colors.aiPurple.opacity(0.25) : Color.clear,
                radius: 24,
                y: 8
            )
            // Layer 3: Crisp definition
            .shadow(
                color: Color.black.opacity(0.30),
                radius: 8,
                y: 4
            )
    }
}

// MARK: - Orb Button Style

private struct OrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Action Tray Item

enum ActionTrayItemType: String, CaseIterable, Identifiable {
    case templates = "Templates"
    case voice = "Voice"
    case calendar = "Calendar"
    case category = "Tag"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .templates: return "doc.on.doc"
        case .voice: return "mic.fill"
        case .calendar: return "calendar"
        case .category: return "tag"
        }
    }

    var color: Color {
        switch self {
        case .templates: return Theme.Colors.aiPurple
        case .voice: return Color.red
        case .calendar: return Theme.Colors.aiBlue
        case .category: return Theme.Colors.aiOrange
        }
    }
}

struct InputV2ActionTrayButton: View {
    let item: ActionTrayItemType
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsService.shared.selectionFeedback()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(item.color)
                }

                Text(item.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Backward Compatibility Extension

extension TaskInputBarV2 {
    /// Convenience initializer for backward compatibility with the old TaskInputBar interface
    /// Converts TaskInputData to just the title string for legacy callers
    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        onSubmit: @escaping (String) -> Void,
        onVoiceInput: (() -> Void)? = nil
    ) {
        self._text = text
        self.isFocused = isFocused
        // Convert TaskInputData callback to String callback
        self.onSubmit = { data in
            onSubmit(data.title)
        }
        self.onVoiceInput = onVoiceInput
    }
}

// MARK: - Preview

#Preview("Task Input Bar V2 - Collapsed") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    TaskInputBarV2(
                        text: $text,
                        isFocused: $isFocused,
                        onSubmit: { (data: TaskInputData) in
                            print("Submitted: \(data.title)")
                        }
                    )
                    .padding(.bottom, 20)
                }
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Task Input Bar V2 - Focused") {
    struct PreviewWrapper: View {
        @State private var text = "Call mom tomorrow at 5pm"
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    TaskInputBarV2(
                        text: $text,
                        isFocused: $isFocused,
                        onSubmit: { (data: TaskInputData) in }
                    )
                    .padding(.bottom, 20)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
