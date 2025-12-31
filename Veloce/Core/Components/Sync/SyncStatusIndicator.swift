//
//  SyncStatusIndicator.swift
//  Veloce
//
//  Beautiful Living Cosmos Sync Status Indicator
//  Shows sync state with cosmic animations and orbital effects
//

import SwiftUI

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    let syncState: SyncState
    let pendingCount: Int
    let onTap: (() -> Void)?

    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1
    @State private var orbitalRotation: Double = 0
    @State private var glowIntensity: CGFloat = 0.5

    init(
        syncState: SyncState,
        pendingCount: Int = 0,
        onTap: (() -> Void)? = nil
    ) {
        self.syncState = syncState
        self.pendingCount = pendingCount
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                // Outer glow
                SwiftUI.Circle()
                    .fill(glowColor.opacity(0.2 * glowIntensity))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)

                // Orbital ring (when syncing)
                if case .syncing = syncState {
                    orbitalRing
                }

                // Main indicator
                SwiftUI.Circle()
                    .fill(backgroundGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        SwiftUI.Circle()
                            .stroke(borderGradient, lineWidth: 1)
                    )
                    .scaleEffect(pulse)

                // Icon
                iconView
                    .rotationEffect(.degrees(rotation))

                // Pending badge
                if pendingCount > 0 && syncState != .syncing(progress: 0) {
                    pendingBadge
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear { startAnimations() }
        .onChange(of: syncState) { _, _ in updateAnimations() }
    }

    // MARK: - Orbital Ring

    private var orbitalRing: some View {
        ZStack {
            // Outer orbit
            SwiftUI.Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore.opacity(0),
                            Theme.CelestialColors.plasmaCore.opacity(0.6),
                            Theme.CelestialColors.nebulaEdge.opacity(0.3),
                            Theme.CelestialColors.plasmaCore.opacity(0)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(orbitalRotation))

            // Orbiting particle
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.plasmaCore)
                .frame(width: 4, height: 4)
                .offset(x: 20)
                .rotationEffect(.degrees(orbitalRotation))
                .shadow(color: Theme.CelestialColors.plasmaCore, radius: 4)
        }
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        switch syncState {
        case .idle:
            Image(systemName: "checkmark.icloud")
                .dynamicTypeFont(base: 14, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)

        case .syncing(let progress):
            if progress > 0 {
                // Progress ring
                SwiftUI.Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.CelestialColors.plasmaCore, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-90))
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .dynamicTypeFont(base: 12, weight: .semibold)
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
            }

        case .success:
            Image(systemName: "checkmark")
                .dynamicTypeFont(base: 14, weight: .bold)
                .foregroundStyle(Theme.CelestialColors.auroraGreen)

        case .error:
            Image(systemName: "exclamationmark.triangle")
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(Theme.CelestialColors.urgencyCritical)

        case .offline:
            Image(systemName: "icloud.slash")
                .dynamicTypeFont(base: 12, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starGhost)
        }
    }

    // MARK: - Pending Badge

    private var pendingBadge: some View {
        Text("\(min(pendingCount, 99))")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Theme.CelestialColors.nebulaCore)
            )
            .offset(x: 14, y: -14)
    }

    // MARK: - Colors

    private var glowColor: Color {
        switch syncState {
        case .idle: return Theme.CelestialColors.starDim
        case .syncing: return Theme.CelestialColors.plasmaCore
        case .success: return Theme.CelestialColors.auroraGreen
        case .error: return Theme.CelestialColors.urgencyCritical
        case .offline: return Theme.CelestialColors.starGhost
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Theme.CelestialColors.nebulaDust,
                Theme.CelestialColors.abyss
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                glowColor.opacity(0.4),
                glowColor.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        updateAnimations()
    }

    private func updateAnimations() {
        switch syncState {
        case .syncing:
            // Continuous rotation for sync icon
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // Orbital animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                orbitalRotation = 360
            }
            // Pulse
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = 1.05
                glowIntensity = 1
            }

        case .success:
            rotation = 0
            orbitalRotation = 0
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                pulse = 1.2
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                pulse = 1
                glowIntensity = 1
            }

        case .error:
            rotation = 0
            orbitalRotation = 0
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                glowIntensity = 1
            }
            pulse = 1

        default:
            withAnimation(.easeOut(duration: 0.3)) {
                rotation = 0
                orbitalRotation = 0
                pulse = 1
                glowIntensity = 0.5
            }
        }
    }
}

// MARK: - Expanded Sync Status View

struct SyncStatusView: View {
    @State private var syncEngine = SyncEngine.shared
    @State private var offlineManager = OfflineManager.shared

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed indicator
            SyncStatusIndicator(
                syncState: syncEngine.syncState,
                pendingCount: syncEngine.pendingCount
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // Expanded details
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status text
            HStack(spacing: 6) {
                SwiftUI.Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(syncEngine.syncState.displayText)
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }

            // Last sync time
            if let lastSync = syncEngine.lastSuccessfulSync {
                Text("Last sync: \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(Theme.Typography.cosmosMetaSmall)
                    .foregroundStyle(Theme.CelestialColors.starGhost)
            }

            // Pending operations
            if syncEngine.pendingCount > 0 {
                Text("\(syncEngine.pendingCount) changes pending")
                    .font(Theme.Typography.cosmosMetaSmall)
                    .foregroundStyle(Theme.CelestialColors.nebulaEdge)
            }

            // Manual sync button
            if offlineManager.isOnline && !syncEngine.syncState.isActive {
                Button {
                    Task {
                        await syncEngine.performFullSync()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.CelestialColors.abyss)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.CelestialColors.glassBorder(opacity: 0.15), lineWidth: 0.5)
                )
        )
        .padding(.top, 8)
    }

    private var statusColor: Color {
        switch syncEngine.syncState {
        case .idle: return Theme.CelestialColors.starDim
        case .syncing: return Theme.CelestialColors.plasmaCore
        case .success: return Theme.CelestialColors.auroraGreen
        case .error: return Theme.CelestialColors.urgencyCritical
        case .offline: return Theme.CelestialColors.starGhost
        }
    }
}

// MARK: - Compact Sync Pill

struct SyncPill: View {
    let syncState: SyncState
    let pendingCount: Int

    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 6) {
            // Icon
            syncIcon
                .rotationEffect(.degrees(rotation))

            // Text
            Text(pillText)
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(textColor)

            // Pending count
            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Theme.CelestialColors.nebulaCore)
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.CelestialColors.nebulaDust.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(borderColor.opacity(0.3), lineWidth: 0.5)
                )
        )
        .onAppear { updateAnimation() }
        .onChange(of: syncState) { _, _ in updateAnimation() }
    }

    @ViewBuilder
    private var syncIcon: some View {
        switch syncState {
        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .dynamicTypeFont(base: 10, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.plasmaCore)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .dynamicTypeFont(base: 10)
                .foregroundStyle(Theme.CelestialColors.auroraGreen)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .dynamicTypeFont(base: 10)
                .foregroundStyle(Theme.CelestialColors.urgencyCritical)
        case .offline:
            Image(systemName: "icloud.slash")
                .dynamicTypeFont(base: 10)
                .foregroundStyle(Theme.CelestialColors.starGhost)
        case .idle:
            Image(systemName: "checkmark.icloud.fill")
                .dynamicTypeFont(base: 10)
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
    }

    private var pillText: String {
        switch syncState {
        case .syncing(let progress):
            return progress > 0 ? "\(Int(progress * 100))%" : "Syncing"
        case .success:
            return "Synced"
        case .error:
            return "Error"
        case .offline:
            return "Offline"
        case .idle:
            return pendingCount > 0 ? "Pending" : "Synced"
        }
    }

    private var textColor: Color {
        switch syncState {
        case .syncing: return Theme.CelestialColors.plasmaCore
        case .success: return Theme.CelestialColors.auroraGreen
        case .error: return Theme.CelestialColors.urgencyCritical
        case .offline: return Theme.CelestialColors.starGhost
        case .idle: return Theme.CelestialColors.starDim
        }
    }

    private var borderColor: Color {
        switch syncState {
        case .syncing: return Theme.CelestialColors.plasmaCore
        case .success: return Theme.CelestialColors.auroraGreen
        case .error: return Theme.CelestialColors.urgencyCritical
        case .offline: return Theme.CelestialColors.starGhost
        case .idle: return Theme.CelestialColors.starDim
        }
    }

    private func updateAnimation() {
        if case .syncing = syncState {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                rotation = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 30) {
            SyncStatusIndicator(syncState: .idle, pendingCount: 0)
            SyncStatusIndicator(syncState: .syncing(progress: 0.45), pendingCount: 3)
            SyncStatusIndicator(syncState: .success(syncedCount: 5), pendingCount: 0)
            SyncStatusIndicator(syncState: .error(message: "Failed"), pendingCount: 2)
            SyncStatusIndicator(syncState: .offline, pendingCount: 5)

            Divider()

            SyncPill(syncState: .syncing(progress: 0.65), pendingCount: 3)
            SyncPill(syncState: .success(syncedCount: 0), pendingCount: 0)
            SyncPill(syncState: .offline, pendingCount: 12)
        }
    }
}
