//
//  VeloceApp.swift
//  Veloce
//
//  Main App Entry Point
//  AI-Powered Task Management with Gamification
//

import SwiftUI
import SwiftData

// MARK: - Veloce App

@main
struct VeloceApp: App {
    // MARK: SwiftData
    let modelContainer: ModelContainer

    // MARK: App State
    @State private var appViewModel = AppViewModel()

    // MARK: Initialization
    init() {
        // Configure SwiftData model container
        let schema = Schema([
            TaskItem.self,
            User.self,
            Goal.self,
            Achievement.self,
            TaskTemplate.self,
            NotesLine.self,
            JournalEntry.self,
            DailyChallenge.self,
            // Focus/App Blocking models
            FocusSessionRecord.self,
            FocusBlockList.self,
            ScheduledFocusSession.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // If schema migration fails, try deleting the old database and creating fresh
            print("⚠️ ModelContainer creation failed: \(error)")
            print("⚠️ Attempting to reset database...")

            // Delete existing SwiftData files
            if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = url.appendingPathComponent("default.store")
                let shmURL = url.appendingPathComponent("default.store-shm")
                let walURL = url.appendingPathComponent("default.store-wal")

                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: shmURL)
                try? FileManager.default.removeItem(at: walURL)

                print("✅ Old database files removed, creating fresh container...")
            }

            // Try again with fresh database
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
                print("✅ Fresh ModelContainer created successfully")
            } catch {
                fatalError("Failed to create model container even after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .task {
                    await appViewModel.initialize(context: modelContainer.mainContext)
                }
        }
        .commands {
            VeloceCommands()
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            switch appViewModel.appState {
            case .loading:
                LoadingView()

            case .freeTrialWelcome:
                FreeTrialWelcomeView()

            case .unauthenticated:
                AuthView(initialScreen: appViewModel.preferSignUp ? .signUp : .signIn)

            case .onboarding:
                JourneyOnboardingContainer(viewModel: JourneyOnboardingViewModel())

            case .paywall:
                PaywallView()

            case .authenticated:
                MainTabView()
                    .withOfflineOverlay()
            }
        }
        .animation(Theme.Animation.standard, value: appViewModel.appState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var showContent = false
    @State private var logoGlow: Double = 0.6
    @State private var logoScale: CGFloat = 0.9

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Aurora background - consistent with auth
                AuroraBackground.auth

                VStack(spacing: Aurora.Layout.spacingXL) {
                    Spacer()

                    // Animated App Logo
                    AppLogoView(
                        size: .large,
                        isAnimating: true,
                        showParticles: true
                    )
                    .scaleEffect(logoScale)
                    .opacity(showContent ? 1 : 0)

                    // Editorial thin typography - matching AuthView
                    VStack(spacing: Aurora.Layout.spacingSmall) {
                        Text("MyTasksAI")
                            .font(.system(size: 42, weight: .thin, design: .default))
                            .foregroundStyle(Aurora.Colors.textPrimary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)

                        Text("AI-Powered Productivity")
                            .font(.system(size: 15))
                            .foregroundStyle(Aurora.Colors.textSecondary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                    }

                    // Subtle loading indicator
                    ProgressView()
                        .tint(Aurora.Colors.electric)
                        .scaleEffect(0.9)
                        .opacity(showContent ? 0.8 : 0)
                        .padding(.top, Aurora.Layout.spacing)

                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Fade in content
        withAnimation(Aurora.Animation.spring.delay(0.2)) {
            showContent = true
        }

        // Logo breathing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            logoScale = 1.05
        }

        // Glow pulse
        withAnimation(Aurora.Animation.glowPulse) {
            logoGlow = 0.9
        }
    }
}
