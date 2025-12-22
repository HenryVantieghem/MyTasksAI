//
//  QuickCaptureWidget.swift
//  Veloce
//

import SwiftUI

struct QuickCaptureWidget: View {
    @Binding var isExpanded: Bool
    @State private var taskText = ""
    var onSubmit: (String) -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isExpanded {
                    expandedView
                } else {
                    collapsedView
                }
            }
            .padding()
        }
    }

    private var collapsedView: some View {
        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExpanded = true } } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 10)
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var expandedView: some View {
        HStack(spacing: 12) {
            TextField("Quick task...", text: $taskText)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onSubmit { submitTask() }

            Button { submitTask() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(taskText.isEmpty ? .gray : Theme.Colors.aiPurple)
            }
            .disabled(taskText.isEmpty)

            Button { withAnimation(.spring()) { isExpanded = false; taskText = "" } } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func submitTask() {
        guard !taskText.isEmpty else { return }
        onSubmit(taskText)
        HapticsService.shared.taskComplete()
        withAnimation(.spring()) {
            taskText = ""
            isExpanded = false
        }
    }
}

struct QuickCaptureOverlay: View {
    @State private var isExpanded = false
    var onSubmit: (String) -> Void

    var body: some View {
        QuickCaptureWidget(isExpanded: $isExpanded, onSubmit: onSubmit)
    }
}
