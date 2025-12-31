//
//  AchievementShowcase.swift
//  Veloce
//

import SwiftUI

struct AchievementShowcase: View {
    let achievements: [Achievement]
    @State private var selectedAchievement: Achievement?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                        .onTapGesture { selectedAchievement = achievement }
                }
            }
            .padding()
        }
        .background(VoidBackground())
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if achievement.isUnlocked {
                    SwiftUI.Circle()
                        .fill(RadialGradient(colors: [Theme.Colors.aiGold.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 40))
                        .blur(radius: 10)
                        .opacity(glowOpacity)
                }
                Image(systemName: achievement.icon)
                    .dynamicTypeFont(base: 32)
                    .foregroundStyle(achievement.isUnlocked ? LinearGradient(colors: [Theme.Colors.aiGold, .orange], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
            }
            .frame(width: 70, height: 70)

            Text(achievement.title)
                .font(.caption.bold())
                .foregroundStyle(achievement.isUnlocked ? .white : .white.opacity(0.4))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 120)
        .voidCard()
        .opacity(achievement.isUnlocked ? 1 : 0.6)
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever()) { glowOpacity = 0.6 }
            }
        }
    }
}

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: achievement.icon)
                .dynamicTypeFont(base: 64)
                .foregroundStyle(achievement.isUnlocked ? Theme.Colors.aiGold : .gray)
            Text(achievement.title).font(.title2.bold()).foregroundStyle(.white)
            Text(achievement.achievementDescription).font(.body).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
            if achievement.isUnlocked, let date = achievement.unlockedAt {
                Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Button("Close") { dismiss() }.buttonStyle(.glass)
        }
        .padding(32)
        .presentationDetents([.medium])
        .background(VoidBackground())
    }
}
