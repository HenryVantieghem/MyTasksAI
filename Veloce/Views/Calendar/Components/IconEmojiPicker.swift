//
//  IconEmojiPicker.swift
//  Veloce
//
//  Icon and Emoji Picker for Task Personalization
//  Allows users to customize task appearance with SF Symbols or emojis
//

import SwiftUI

// MARK: - Icon Emoji Picker

/// Sheet for selecting task icons or emojis
struct IconEmojiPicker: View {
    @Binding var selectedIcon: String?
    @Binding var selectedEmoji: String?
    @Environment(\.dismiss) private var dismiss

    @State private var mode: PickerMode = .sfSymbols
    @State private var searchText: String = ""

    enum PickerMode: String, CaseIterable {
        case sfSymbols = "Symbols"
        case emoji = "Emoji"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode toggle
                modeToggle

                // Search bar
                searchBar

                // Grid content
                ScrollView {
                    switch mode {
                    case .sfSymbols:
                        symbolsGrid
                    case .emoji:
                        emojiGrid
                    }
                }
            }
            .background(Color(red: 0.06, green: 0.06, blue: 0.10))
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        selectedIcon = nil
                        selectedEmoji = nil
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.aiCyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $mode) {
            ForEach(PickerMode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))

            TextField("Search", text: $searchText)
                .foregroundStyle(.white)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.08))
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Symbols Grid

    private var symbolsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
            spacing: 12
        ) {
            ForEach(filteredSymbols, id: \.self) { symbol in
                SymbolButton(
                    symbol: symbol,
                    isSelected: selectedIcon == symbol,
                    onTap: {
                        HapticsService.shared.selectionFeedback()
                        selectedIcon = symbol
                        selectedEmoji = nil
                    }
                )
            }
        }
        .padding()
    }

    private var filteredSymbols: [String] {
        let allSymbols = TiimoDesignTokens.IconCategories.all
        if searchText.isEmpty {
            return allSymbols
        }
        return allSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Emoji Grid

    private var emojiGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Categories
            ForEach(emojiCategories, id: \.name) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.name)
                        .dynamicTypeFont(base: 13, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 4)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8),
                        spacing: 8
                    ) {
                        ForEach(filteredEmojis(in: category.emojis), id: \.self) { emoji in
                            EmojiButton(
                                emoji: emoji,
                                isSelected: selectedEmoji == emoji,
                                onTap: {
                                    HapticsService.shared.selectionFeedback()
                                    selectedEmoji = emoji
                                    selectedIcon = nil
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func filteredEmojis(in emojis: [String]) -> [String] {
        if searchText.isEmpty {
            return emojis
        }
        // For emojis, just show all if there's a search since emoji names aren't directly searchable
        return emojis
    }

    private var emojiCategories: [(name: String, emojis: [String])] {
        [
            ("Productivity", TiimoDesignTokens.EmojiCategories.productivity),
            ("Communication", TiimoDesignTokens.EmojiCategories.communication),
            ("Creative", TiimoDesignTokens.EmojiCategories.creative),
            ("Learning", TiimoDesignTokens.EmojiCategories.learning),
            ("Wellness", TiimoDesignTokens.EmojiCategories.wellness),
            ("Errands", TiimoDesignTokens.EmojiCategories.errands),
            ("Time", TiimoDesignTokens.EmojiCategories.time),
            ("Food & Home", TiimoDesignTokens.EmojiCategories.food)
        ]
    }
}

// MARK: - Symbol Button

struct SymbolButton: View {
    let symbol: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Image(systemName: symbol)
                .dynamicTypeFont(base: 22)
                .foregroundStyle(isSelected ? Theme.Colors.aiCyan : .white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Theme.Colors.aiCyan.opacity(0.2) : .white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Theme.Colors.aiCyan.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Emoji Button

struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text(emoji)
                .dynamicTypeFont(base: 26)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Theme.Colors.aiCyan.opacity(0.2) : .white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Theme.Colors.aiCyan.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Icon Preview Badge

/// Small badge showing the selected icon or emoji
struct IconPreviewBadge: View {
    let icon: String?
    let emoji: String?
    let taskType: TaskType
    let size: CGFloat

    var body: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(taskType.tiimoColor.opacity(0.3))
                .frame(width: size, height: size)

            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: size * 0.5))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: taskType.defaultIcon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview("Icon Emoji Picker") {
    IconEmojiPicker(
        selectedIcon: .constant(nil),
        selectedEmoji: .constant(nil)
    )
}
