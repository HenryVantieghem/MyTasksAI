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
        do {
            let schema = Schema([
                TaskItem.self,
                User.self,
                Goal.self,
                Achievement.self,
                TaskTemplate.self
            ])

            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .modelContainer(modelContainer)
                .task {
                    await appViewModel.initialize(context: modelContainer.mainContext)
                }
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

            case .unauthenticated:
                AuthView()

            case .onboarding:
                OnboardingContainerView(viewModel: OnboardingViewModel())

            case .authenticated:
                MainContainerView()
            }
        }
        .animation(Theme.Animation.standard, value: appViewModel.appState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            IridescentBackground(intensity: 0.5)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                // Animated logo
                ZStack {
                    IridescentOrb(size: 100)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(Theme.Colors.accent)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 3).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }

                Text("MyTasksAI")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)

                ProgressView()
                    .tint(Theme.Colors.accent)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
