//
//  ActionTray.swift
//  Veloce
//
//  Claude-style Action Tray with expanded actions and template management
//  Beautiful grid layout with Liquid Glass effects
//

import SwiftUI

// MARK: - Action Tray Item

enum ActionTrayItem: String, CaseIterable, Identifiable {
    case templates = "Templates"
    case voice = "Voice"
    case calendar = "Calendar"
    case category = "Tags"
    case attachment = "Attach"
    case location = "Location"
    case reminder = "Remind"
    case subtasks = "Subtasks"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .templates: return "bolt.fill"
        case .voice: return "mic.fill"
        case .calendar: return "calendar"
        case .category: return "tag.fill"
        case .attachment: return "paperclip"
        case .location: return "location.fill"
        case .reminder: return "bell.fill"
        case .subtasks: return "list.bullet.indent"
        }
    }

    var color: Color {
        switch self {
        case .templates: return Theme.Colors.aiPurple
        case .voice: return Color.red
        case .calendar: return Theme.Colors.aiBlue
        case .category: return Theme.Colors.aiGreen
        case .attachment: return Theme.Colors.aiOrange
        case .location: return Theme.Colors.aiCyan
        case .reminder: return Theme.Colors.aiPink
        case .subtasks: return Theme.CelestialColors.nebulaCore
        }
    }

    /// Primary actions shown in the main tray
    static var primaryItems: [ActionTrayItem] {
        [.templates, .voice, .calendar, .category]
    }

    /// All actions for full expanded tray
    static var allItems: [ActionTrayItem] {
        allCases
    }
}

// MARK: - Action Tray Button

struct ActionTrayButton: View {
    let item: ActionTrayItem
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                // Icon with ambient glow
                ZStack {
                    // Glow
                    Circle()
                        .fill(item.color.opacity(0.25))
                        .frame(width: 44, height: 44)
                        .blur(radius: 6)

                    // Background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    item.color.opacity(0.2),
                                    item.color.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(item.color.opacity(0.3), lineWidth: 0.5)
                        }

                    // Icon
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Label
                Text(item.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(item.rawValue)
    }
}

// MARK: - Quick Add Template (Enhanced)

struct QuickAddTemplate: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var icon: String
    var colorName: String

    init(id: UUID = UUID(), title: String, icon: String, color: Color) {
        self.id = id
        self.title = title
        self.icon = icon
        self.colorName = QuickAddTemplate.colorToName(color)
    }

    var color: Color {
        QuickAddTemplate.nameToColor(colorName)
    }

    private static func colorToName(_ color: Color) -> String {
        switch color {
        case Theme.Colors.aiBlue: return "aiBlue"
        case Theme.Colors.aiGreen: return "aiGreen"
        case Theme.Colors.aiPurple: return "aiPurple"
        case Theme.Colors.aiOrange: return "aiOrange"
        case Theme.Colors.aiCyan: return "aiCyan"
        case Theme.Colors.aiPink: return "aiPink"
        default: return "aiPurple"
        }
    }

    private static func nameToColor(_ name: String) -> Color {
        switch name {
        case "aiBlue": return Theme.Colors.aiBlue
        case "aiGreen": return Theme.Colors.aiGreen
        case "aiPurple": return Theme.Colors.aiPurple
        case "aiOrange": return Theme.Colors.aiOrange
        case "aiCyan": return Theme.Colors.aiCyan
        case "aiPink": return Theme.Colors.aiPink
        default: return Theme.Colors.aiPurple
        }
    }

    static let defaults: [QuickAddTemplate] = [
        QuickAddTemplate(title: "Email", icon: "envelope.fill", color: Theme.Colors.aiBlue),
        QuickAddTemplate(title: "Call", icon: "phone.fill", color: Theme.Colors.aiGreen),
        QuickAddTemplate(title: "Meeting", icon: "person.2.fill", color: Theme.Colors.aiPurple),
        QuickAddTemplate(title: "Review", icon: "doc.text.fill", color: Theme.Colors.aiOrange),
        QuickAddTemplate(title: "Exercise", icon: "figure.run", color: Theme.Colors.aiCyan),
        QuickAddTemplate(title: "Shopping", icon: "cart.fill", color: Theme.Colors.aiPink),
        QuickAddTemplate(title: "Research", icon: "magnifyingglass", color: Theme.Colors.aiPurple),
        QuickAddTemplate(title: "Write", icon: "pencil", color: Theme.Colors.aiBlue)
    ]
}

// MARK: - Quick Add Sheet (Redesigned)

struct QuickAddSheet: View {
    @Binding var templates: [QuickAddTemplate]
    let onSelect: (QuickAddTemplate) -> Void
    let onAddCustom: () -> Void

    @State private var searchText = ""
    @State private var showAddTemplate = false
    @Environment(\.dismiss) private var dismiss

    private var filteredTemplates: [QuickAddTemplate] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Search bar
                    searchBar

                    // Recent section
                    if searchText.isEmpty {
                        recentSection
                    }

                    // All templates grid
                    templatesGrid

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.clear)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.Colors.aiPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddTemplate) {
                AddTemplateSheet(templates: $templates)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search templates...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(.primary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("Recent")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templates.prefix(4)) { template in
                        RecentTemplateChip(template: template) {
                            HapticsService.shared.selectionFeedback()
                            onSelect(template)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Templates Grid

    private var templatesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("All Templates")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredTemplates) { template in
                    TemplateGridItem(template: template) {
                        HapticsService.shared.selectionFeedback()
                        onSelect(template)
                    }
                }

                // Add custom button
                AddCustomTemplateButton {
                    onAddCustom()
                }
            }
        }
    }
}

// MARK: - Recent Template Chip

struct RecentTemplateChip: View {
    let template: QuickAddTemplate
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(template.color)

                Text(template.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(template.color.opacity(0.12))
                    .overlay {
                        Capsule()
                            .stroke(template.color.opacity(0.25), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Grid Item

struct TemplateGridItem: View {
    let template: QuickAddTemplate
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(template.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .blur(radius: 4)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    template.color.opacity(0.25),
                                    template.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(template.color.opacity(0.3), lineWidth: 0.5)
                        }

                    Image(systemName: template.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(template.color)
                }

                Text(template.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Add Custom Template Button

struct AddCustomTemplateButton: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("Custom")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Template Sheet

struct AddTemplateSheet: View {
    @Binding var templates: [QuickAddTemplate]
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor: Color = Theme.Colors.aiPurple

    private let iconOptions = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "book.fill", "briefcase.fill", "cart.fill",
        "envelope.fill", "phone.fill", "video.fill", "camera.fill",
        "pencil", "paintbrush.fill", "doc.text.fill", "folder.fill",
        "gear", "wrench.fill", "hammer.fill", "person.fill"
    ]

    private let colorOptions: [Color] = [
        Theme.Colors.aiPurple, Theme.Colors.aiBlue, Theme.Colors.aiGreen,
        Theme.Colors.aiOrange, Theme.Colors.aiCyan, Theme.Colors.aiPink
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    previewCard

                    // Title input
                    titleInput

                    // Icon picker
                    iconPicker

                    // Color picker
                    colorPicker

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.clear)
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(title.isEmpty)
                    .foregroundStyle(title.isEmpty ? .secondary : Theme.Colors.aiPurple)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private var previewCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(selectedColor.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .blur(radius: 6)

                Circle()
                    .fill(selectedColor.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Circle()
                            .stroke(selectedColor.opacity(0.4), lineWidth: 1)
                    }

                Image(systemName: selectedIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(selectedColor)
            }

            Text(title.isEmpty ? "Template Name" : title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(title.isEmpty ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                }
        }
    }

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Enter template name", text: $title)
                .font(.system(size: 16))
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        }
                }
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.white.opacity(0.06))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selectedIcon == icon ? selectedColor.opacity(0.5) : Color.white.opacity(0.1),
                                            lineWidth: selectedIcon == icon ? 1.5 : 0.5
                                        )
                                }

                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(selectedIcon == icon ? selectedColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(colorOptions, id: \.self) { color in
                    Button {
                        selectedColor = color
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)

                            if selectedColor == color {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func saveTemplate() {
        let template = QuickAddTemplate(
            title: title,
            icon: selectedIcon,
            color: selectedColor
        )
        templates.append(template)
        HapticsService.shared.success()
        dismiss()
    }
}

// MARK: - Previews

#Preview("Quick Add Sheet") {
    QuickAddSheet(
        templates: .constant(QuickAddTemplate.defaults),
        onSelect: { _ in },
        onAddCustom: { }
    )
    .preferredColorScheme(.dark)
}

#Preview("Action Tray Buttons") {
    HStack(spacing: 20) {
        ForEach(ActionTrayItem.primaryItems) { item in
            ActionTrayButton(item: item) { }
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Add Template Sheet") {
    AddTemplateSheet(templates: .constant([]))
        .preferredColorScheme(.dark)
}
