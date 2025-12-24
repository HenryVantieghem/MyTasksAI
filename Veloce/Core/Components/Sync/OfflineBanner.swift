//
//  OfflineBanner.swift
//  Veloce
//
//  Subtle Offline Mode Indicator
//  Non-intrusive banner that appears when offline
//

import SwiftUI

// MARK: - Offline Banner

struct OfflineBanner: View {
    @State private var offlineManager = OfflineManager.shared
    @State private var syncEngine = SyncEngine.shared

    @State private var isExpanded = false
    @State private var showBanner = false
    @State private var pulseOpacity: CGFloat = 0.6

    var body: some View {
        if showBanner {
            bannerContent
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
        }
    }

    private var bannerContent: some View {
        VStack(spacing: 0) {
            // Main banner
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Pulsing indicator
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .opacity(pulseOpacity)
                        .shadow(color: statusColor.opacity(0.5), radius: 4)

                    // Status icon
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(statusColor)

                    // Status text
                    Text(statusText)
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    Spacer()

                    // Pending count
                    if syncEngine.pendingCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 10))
                            Text("\(syncEngine.pendingCount)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Theme.CelestialColors.nebulaEdge)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.CelestialColors.nebulaEdge.opacity(0.15))
                        )
                    }

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bannerBackground)
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded {
                expandedContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear {
            startPulseAnimation()
            observeConnectionState()
        }
        .onChange(of: offlineManager.connectionState) { _, newState in
            updateBannerVisibility(for: newState)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(Theme.CelestialColors.starGhost.opacity(0.2))

            // Offline info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.starGhost)

                    Text("Your data is saved locally and will sync when you're back online.")
                        .font(Theme.Typography.cosmosWhisperSmall)
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Offline duration
                if !offlineManager.offlineDurationText.isEmpty {
                    Text(offlineManager.offlineDurationText)
                        .font(Theme.Typography.cosmosMetaSmall)
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                        .padding(.leading, 20)
                }
            }

            // Pending operations summary
            if syncEngine.pendingCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.CelestialColors.nebulaEdge)

                    Text("\(syncEngine.pendingCount) changes will sync automatically")
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.nebulaEdge)
                }
            }

            // Connection quality (if connecting)
            if offlineManager.connectionState == .connecting {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.CelestialColors.plasmaCore)

                    Text("Attempting to reconnect...")
                        .font(Theme.Typography.cosmosMeta)
                        .foregroundStyle(Theme.CelestialColors.plasmaCore)
                }
            }

            // Retry button (if online but sync failed)
            if offlineManager.isOnline && syncEngine.failedOperationsCount > 0 {
                Button {
                    Task {
                        await syncEngine.processPendingQueue()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Sync")
                    }
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.plasmaCore)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Theme.CelestialColors.plasmaCore.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Styling

    private var bannerBackground: some View {
        LinearGradient(
            colors: [
                Theme.CelestialColors.abyss,
                Theme.CelestialColors.nebulaDust.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var statusColor: Color {
        switch offlineManager.connectionState {
        case .offline:
            return Theme.CelestialColors.urgencyNear
        case .connecting:
            return Theme.CelestialColors.plasmaCore
        case .online:
            return Theme.CelestialColors.auroraGreen
        }
    }

    private var statusIcon: String {
        switch offlineManager.connectionState {
        case .offline:
            return "wifi.slash"
        case .connecting:
            return "wifi.exclamationmark"
        case .online:
            return "wifi"
        }
    }

    private var statusText: String {
        switch offlineManager.connectionState {
        case .offline:
            return "Offline Mode"
        case .connecting:
            return "Reconnecting..."
        case .online:
            if syncEngine.pendingCount > 0 {
                return "Syncing..."
            }
            return "Back Online"
        }
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseOpacity = 1
        }
    }

    private func observeConnectionState() {
        updateBannerVisibility(for: offlineManager.connectionState)
    }

    private func updateBannerVisibility(for state: ConnectionState) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch state {
            case .offline, .connecting:
                showBanner = true
            case .online:
                // Show briefly when coming back online
                showBanner = true
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if offlineManager.isOnline && syncEngine.pendingCount == 0 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showBanner = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Minimal Offline Dot

/// Tiny indicator for status bar area
struct OfflineDot: View {
    @State private var offlineManager = OfflineManager.shared
    @State private var pulse: CGFloat = 1

    var body: some View {
        if !offlineManager.isOnline {
            Circle()
                .fill(Theme.CelestialColors.urgencyNear)
                .frame(width: 6, height: 6)
                .scaleEffect(pulse)
                .shadow(color: Theme.CelestialColors.urgencyNear.opacity(0.5), radius: 3)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        pulse = 1.3
                    }
                }
        }
    }
}

// MARK: - Connection Toast

/// Brief toast when connection state changes
struct ConnectionToast: View {
    let connectionState: ConnectionState
    let onDismiss: () -> Void

    @State private var opacity: CGFloat = 0
    @State private var offset: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)

            Text(message)
                .font(Theme.Typography.cosmosMeta)
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Theme.CelestialColors.nebulaDust)
                .overlay(
                    Capsule()
                        .stroke(iconColor.opacity(0.3), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }

            // Auto-dismiss
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 0
                    offset = -20
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
                onDismiss()
            }
        }
    }

    private var iconName: String {
        switch connectionState {
        case .online: return "wifi"
        case .offline: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        }
    }

    private var iconColor: Color {
        switch connectionState {
        case .online: return Theme.CelestialColors.auroraGreen
        case .offline: return Theme.CelestialColors.urgencyNear
        case .connecting: return Theme.CelestialColors.plasmaCore
        }
    }

    private var message: String {
        switch connectionState {
        case .online: return "Back online"
        case .offline: return "You're offline"
        case .connecting: return "Reconnecting..."
        }
    }
}

// MARK: - View Modifier for Offline Overlay

struct OfflineOverlayModifier: ViewModifier {
    @State private var offlineManager = OfflineManager.shared
    @State private var showToast = false
    @State private var lastState: ConnectionState = .online

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                OfflineBanner()
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ConnectionToast(connectionState: offlineManager.connectionState) {
                        showToast = false
                    }
                    .padding(.bottom, 100)
                }
            }
            .onChange(of: offlineManager.connectionState) { oldState, newState in
                if oldState != newState {
                    showToast = true
                    lastState = newState
                }
            }
    }
}

extension View {
    /// Add offline overlay to any view
    func withOfflineOverlay() -> some View {
        modifier(OfflineOverlayModifier())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            OfflineBanner()

            Spacer()

            ConnectionToast(connectionState: .offline) {}
                .padding(.bottom, 50)
        }
    }
}
