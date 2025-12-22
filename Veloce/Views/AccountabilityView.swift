//
//  AccountabilityView.swift
//  Veloce
//

import SwiftUI

struct AccountabilityView: View {
    @State private var isEnabled = false
    @State private var partnerName = ""
    @State private var showAddPartner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.aiPurple)
                    Text("Accountability")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Stay motivated with friends")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top)

                // Toggle
                Toggle(isOn: $isEnabled) {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Share daily progress")
                    }
                    .foregroundStyle(.white)
                }
                .tint(Theme.Colors.aiPurple)
                .padding()
                .voidCard()

                if isEnabled {
                    // Accountability partner
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accountability Partner")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if partnerName.isEmpty {
                            Button { showAddPartner = true } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Partner")
                                }
                                .foregroundStyle(Theme.Colors.aiPurple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            HStack {
                                Circle()
                                    .fill(Theme.Colors.aiPurple)
                                    .frame(width: 40, height: 40)
                                    .overlay(Text(String(partnerName.prefix(1))).foregroundStyle(.white).font(.headline))
                                VStack(alignment: .leading) {
                                    Text(partnerName).font(.headline).foregroundStyle(.white)
                                    Text("Gets notified on goal completion").font(.caption).foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                                Button { partnerName = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            .padding()
                            .voidCard()
                        }
                    }
                    .padding()
                    .voidCard()

                    // Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "trophy.fill").foregroundStyle(Theme.Colors.aiGold)
                            Text("Weekly Leaderboard").font(.headline).foregroundStyle(.white)
                        }

                        ForEach(0..<5, id: \.self) { i in
                            HStack {
                                Text("\(i + 1)").font(.caption.bold()).foregroundStyle(.white.opacity(0.5)).frame(width: 20)
                                Circle().fill(Theme.Colors.aiPurple.opacity(0.5)).frame(width: 32, height: 32)
                                Text(["You", "Alex", "Jordan", "Sam", "Taylor"][i]).foregroundStyle(.white)
                                Spacer()
                                Text("\(50 - i * 8) tasks").font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .voidCard()
                }
            }
            .padding()
        }
        .background(VoidBackground())
        .navigationTitle("Accountability")
        .sheet(isPresented: $showAddPartner) {
            AddPartnerSheet(partnerName: $partnerName)
        }
    }
}

struct AddPartnerSheet: View {
    @Binding var partnerName: String
    @Environment(\.dismiss) private var dismiss
    @State private var inputName = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Add Accountability Partner").font(.headline).foregroundStyle(.white)
            TextField("Partner's name", text: $inputName)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button("Add Partner") {
                partnerName = inputName
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .disabled(inputName.isEmpty)
        }
        .padding()
        .presentationDetents([.height(250)])
        .background(VoidBackground())
    }
}
