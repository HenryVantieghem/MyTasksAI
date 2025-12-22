//
//  AITaskBuddy.swift
//  Veloce
//

import SwiftUI

struct AITaskBuddy: View {
    let task: TaskItem
    @State private var isExpanded = false
    @State private var response: String = ""
    @State private var isThinking = false

    private let suggestions = ["Break this down for me", "What should I do first?", "Find me resources", "How long will this take?"]

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed state - floating orb
            if !isExpanded {
                Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExpanded = true } } label: {
                    ZStack {
                        Circle().fill(Theme.Colors.aiPurple.opacity(0.2)).frame(width: 60, height: 60).blur(radius: 10)
                        AIOrb(size: .small, animationStyle: .breathing)
                    }
                }
            }

            // Expanded state - chat interface
            if isExpanded {
                VStack(spacing: 16) {
                    HStack {
                        AIOrb(size: .tiny, animationStyle: isThinking ? .thinking : .idle)
                        Text("AI Buddy").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Button { withAnimation(.spring()) { isExpanded = false } } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Text("Working on: \(task.title)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isThinking {
                        OrbitingParticlesThinking().frame(height: 80)
                    } else if !response.isEmpty {
                        Text(response)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Quick suggestions
                    AIBuddyFlowLayout(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button { askBuddy(suggestion) } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .voidCard(borderColor: Theme.Colors.aiPurple)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func askBuddy(_ question: String) {
        isThinking = true
        response = ""
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                isThinking = false
                response = generateResponse(for: question)
            }
        }
    }

    private func generateResponse(for question: String) -> String {
        switch question {
        case "Break this down for me": return "1. Research the topic\n2. Create an outline\n3. Draft the main content\n4. Review and refine\n5. Finalize"
        case "What should I do first?": return "Start with the most challenging part while your energy is high. This sets momentum for the rest."
        case "Find me resources": return "I'd recommend checking relevant documentation, tutorials on YouTube, and community forums for this type of task."
        case "How long will this take?": return "Based on similar tasks, this could take 45-60 minutes of focused work. Consider a Pomodoro session!"
        default: return "I'm here to help! Ask me anything about this task."
        }
    }
}

struct AIBuddyFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? .infinity) {
                width = max(width, lineWidth - spacing)
                height += lineHeight + spacing
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: max(width, lineWidth - spacing), height: height + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
