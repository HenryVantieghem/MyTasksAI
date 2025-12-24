//
//  JoinCircleSheet.swift
//  Veloce
//
//  Sheet for joining an existing circle
//

import SwiftUI

struct JoinCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.aiPurple)
                    .padding(.top, Theme.Spacing.md)

                Text("Enter Invite Code")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                TextField("Invite code", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .padding(.horizontal)

                Button {
                    // TODO: Implement join circle
                    dismiss()
                } label: {
                    Text("Join Circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.Colors.aiPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(inviteCode.isEmpty)
                .opacity(inviteCode.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal)

                Spacer()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Join Circle")
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
    JoinCircleSheet()
}
