//
//  CreateCircleSheet.swift
//  Veloce
//
//  Sheet for creating a new circle
//

import SwiftUI

struct CreateCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var circleName = ""
    @State private var circleDescription = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Circle name input
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Circle Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    TextField("Enter circle name", text: $circleName)
                        .textFieldStyle(.roundedBorder)
                }

                // Description input
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Description (optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    TextField("What is this circle about?", text: $circleDescription)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                // Create button
                Button {
                    // TODO: Implement circle creation
                    dismiss()
                } label: {
                    Text("Create Circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.Colors.aiPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(circleName.isEmpty)
                .opacity(circleName.isEmpty ? 0.5 : 1.0)
            }
            .padding()
            .background(Theme.Colors.background)
            .navigationTitle("Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CreateCircleSheet()
}
