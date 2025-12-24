//
//  DrawingCanvasView.swift
//  Veloce
//
//  Drawing Canvas View - PencilKit integration for journal drawings
//  Supports Apple Pencil and finger drawing with tool palette
//

import SwiftUI
import PencilKit

// MARK: - Drawing Canvas View

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var tool: PKTool
    var isDrawingEnabled: Bool = true
    var onDrawingChange: ((PKDrawing) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.drawingPolicy = .anyInput  // Allow finger and Pencil
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .dark

        // Enable drawing
        canvas.isUserInteractionEnabled = isDrawingEnabled
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Only update tool if changed
        if type(of: canvas.tool) != type(of: tool) ||
           (canvas.tool as? PKInkingTool)?.color != (tool as? PKInkingTool)?.color {
            canvas.tool = tool
        }

        canvas.isUserInteractionEnabled = isDrawingEnabled

        // Update drawing if externally changed
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChange?(canvasView.drawing)
        }
    }
}

// MARK: - Drawing Tool Palette

struct DrawingToolPalette: View {
    @Binding var selectedTool: DrawingTool
    @Binding var selectedColor: Color
    @Binding var strokeWidth: CGFloat
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onDismiss: () -> Void

    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Tool row
            HStack(spacing: Theme.Spacing.md) {
                // Tools
                ForEach(DrawingTool.allCases, id: \.self) { tool in
                    ToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool,
                        action: { selectedTool = tool }
                    )
                }

                Divider()
                    .frame(height: 28)
                    .opacity(0.3)

                // Color picker
                Button {
                    showColorPicker.toggle()
                } label: {
                    SwiftUI.Circle()
                        .fill(selectedColor)
                        .frame(width: 28, height: 28)
                        .overlay {
                            SwiftUI.Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 28)
                    .opacity(0.3)

                // Undo/Redo
                Button {
                    HapticsService.shared.lightImpact()
                    onUndo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    HapticsService.shared.lightImpact()
                    onRedo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                // Clear
                Button {
                    HapticsService.shared.warning()
                    onClear()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.error)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                // Dismiss
                Button {
                    HapticsService.shared.lightImpact()
                    onDismiss()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)

            // Stroke width slider (when not erasing)
            if selectedTool != .eraser {
                strokeWidthSlider
            }

            // Color picker panel
            if showColorPicker {
                colorPickerPanel
            }
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Stroke Width Slider

    private var strokeWidthSlider: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Thin stroke preview
            SwiftUI.Circle()
                .fill(selectedColor)
                .frame(width: 4, height: 4)

            Slider(value: $strokeWidth, in: 1...20)
                .tint(Theme.Colors.accent)

            // Thick stroke preview
            SwiftUI.Circle()
                .fill(selectedColor)
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Color Picker Panel

    private var colorPickerPanel: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(DrawingColors.palette, id: \.self) { color in
                Button {
                    selectedColor = color
                    showColorPicker = false
                    HapticsService.shared.selectionFeedback()
                } label: {
                    SwiftUI.Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if selectedColor == color {
                                SwiftUI.Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Tool Button

struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            Image(systemName: tool.icon)
                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary)
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.accent.opacity(0.15))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.accessibilityLabel)
    }
}

// MARK: - Drawing Tool

enum DrawingTool: String, CaseIterable, Sendable {
    case pen
    case marker
    case pencil
    case eraser

    var icon: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .pencil: return "pencil"
        case .eraser: return "eraser"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .pen: return "Pen tool"
        case .marker: return "Marker tool"
        case .pencil: return "Pencil tool"
        case .eraser: return "Eraser tool"
        }
    }

    func toPKTool(color: UIColor, width: CGFloat) -> PKTool {
        switch self {
        case .pen:
            return PKInkingTool(.pen, color: color, width: width)
        case .marker:
            return PKInkingTool(.marker, color: color, width: width * 2)
        case .pencil:
            return PKInkingTool(.pencil, color: color, width: width)
        case .eraser:
            return PKEraserTool(.vector)
        }
    }
}

// MARK: - Drawing Colors

enum DrawingColors {
    static let palette: [Color] = [
        .white,
        Color(hex: "8B5CF6"),  // Purple
        Color(hex: "3B82F6"),  // Blue
        Color(hex: "06B6D4"),  // Cyan
        Color(hex: "10B981"),  // Green
        Color(hex: "F59E0B"),  // Amber
        Color(hex: "EF4444"),  // Red
        Color(hex: "EC4899"),  // Pink
        .gray
    ]
}

// MARK: - Drawing Canvas Container

/// Full-featured drawing view with toolbar
struct DrawingCanvasContainer: View {
    @Binding var drawing: PKDrawing
    @Binding var isDrawingMode: Bool

    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .white
    @State private var strokeWidth: CGFloat = 3
    @State private var undoManager = UndoManager()

    private var currentPKTool: PKTool {
        selectedTool.toPKTool(color: UIColor(selectedColor), width: strokeWidth)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Canvas
            DrawingCanvasView(
                drawing: $drawing,
                tool: .constant(currentPKTool),
                isDrawingEnabled: isDrawingMode,
                onDrawingChange: { newDrawing in
                    // Handle undo registration here if needed
                }
            )

            // Toolbar
            if isDrawingMode {
                DrawingToolPalette(
                    selectedTool: $selectedTool,
                    selectedColor: $selectedColor,
                    strokeWidth: $strokeWidth,
                    onUndo: { undoManager.undo() },
                    onRedo: { undoManager.redo() },
                    onClear: { drawing = PKDrawing() },
                    onDismiss: { isDrawingMode = false }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Preview

#Preview("Drawing Canvas") {
    struct PreviewWrapper: View {
        @State private var drawing = PKDrawing()
        @State private var tool: PKTool = PKInkingTool(.pen, color: .white, width: 3)

        var body: some View {
            DrawingCanvasView(drawing: $drawing, tool: $tool)
                .background { VoidBackground.journal }
        }
    }
    return PreviewWrapper()
}

#Preview("Drawing Tool Palette") {
    struct PreviewWrapper: View {
        @State private var tool: DrawingTool = .pen
        @State private var color: Color = .white
        @State private var width: CGFloat = 3

        var body: some View {
            VStack {
                Spacer()
                DrawingToolPalette(
                    selectedTool: $tool,
                    selectedColor: $color,
                    strokeWidth: $width,
                    onUndo: {},
                    onRedo: {},
                    onClear: {},
                    onDismiss: {}
                )
            }
            .background { VoidBackground.standard }
        }
    }
    return PreviewWrapper()
}

#Preview("Full Drawing Container") {
    struct PreviewWrapper: View {
        @State private var drawing = PKDrawing()
        @State private var isDrawing = true

        var body: some View {
            DrawingCanvasContainer(drawing: $drawing, isDrawingMode: $isDrawing)
                .background { VoidBackground.journal }
        }
    }
    return PreviewWrapper()
}
