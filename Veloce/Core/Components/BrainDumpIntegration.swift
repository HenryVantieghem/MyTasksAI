//
//  BrainDumpIntegration.swift
//  Veloce
//
//  Integration guide for adding Brain Dump to the tab bar
//  Follow these steps to add the quick-access Brain Dump button
//

import SwiftUI

// MARK: - ============================================
// MARK: - HOW TO ADD BRAIN DUMP BUTTON TO TAB BAR
// MARK: - ============================================

/*

 OPTION 1: Floating Action Button (Recommended)
 =============================================

 Add this floating button overlay to your MainContainerView or root view.
 This provides quick access from anywhere in the app.

 Steps:
 1. Add the @State property to your MainContainerView:

     @State private var showingBrainDump: Bool = false

 2. Add the FAB overlay to your main content:

     .overlay(alignment: .bottomTrailing) {
         BrainDumpFAB(isPresented: $showingBrainDump)
     }

 3. Add the sheet modifier:

     .sheet(isPresented: $showingBrainDump) {
         BrainDumpSheet(
             onTasksCreated: { tasks in
                 // Add tasks to your TasksViewModel
                 // e.g., tasksViewModel.createTasks(tasks)
                 showingBrainDump = false
             },
             onDismiss: {
                 showingBrainDump = false
             }
         )
         .presentationDetents([.medium, .large])
         .presentationDragIndicator(.visible)
     }

 OPTION 2: Tab Bar Item
 ======================

 If using a TabView, add Brain Dump as a dedicated tab:

     TabView(selection: $selectedTab) {
         TasksPageView()
             .tabItem {
                 Label("Tasks", systemImage: "checkmark.circle")
             }
             .tag(0)

         CalendarPageView()
             .tabItem {
                 Label("Calendar", systemImage: "calendar")
             }
             .tag(1)

         // Brain Dump Tab (opens as sheet instead of view)
         Color.clear
             .tabItem {
                 Label("Brain Dump", systemImage: "brain.head.profile")
             }
             .tag(2)
             .onAppear {
                 // Immediately show sheet when this tab is selected
                 if selectedTab == 2 {
                     showingBrainDump = true
                     selectedTab = previousTab // Return to previous tab
                 }
             }

         SettingsView()
             .tabItem {
                 Label("Settings", systemImage: "gear")
             }
             .tag(3)
     }

 OPTION 3: Navigation Bar Button
 ===============================

 Add to your navigation bar for quick access:

     .toolbar {
         ToolbarItem(placement: .primaryAction) {
             Button {
                 showingBrainDump = true
             } label: {
                 Image(systemName: "brain.head.profile")
                     .symbolEffect(.pulse, options: .repeating)
             }
         }
     }

*/

// MARK: - Brain Dump Floating Action Button

/// Floating Action Button for quick Brain Dump access
struct BrainDumpFAB: View {
    @Binding var isPresented: Bool
    @State private var isPulsing: Bool = false

    var body: some View {
        Button {
            HapticsService.shared.impact()
            isPresented = true
        } label: {
            ZStack {
                // Background glow
                SwiftUI.Circle()
                    .fill(Theme.Colors.accent.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .blur(radius: 8)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)

                // Main button
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 10, y: 4)

                // Icon
                Image(systemName: "brain.head.profile")
                    .dynamicTypeFont(base: 24, weight: .semibold)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 100) // Above tab bar
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Brain Dump Quick Access Card

/// Card that can be placed in the Tasks view for Brain Dump access
struct BrainDumpQuickAccessCard: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            HapticsService.shared.softImpact()
            isPresented = true
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(Theme.Colors.accent.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "brain.head.profile")
                        .dynamicTypeFont(base: 20)
                        .foregroundStyle(Theme.Colors.accent)
                        .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5))
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brain Dump")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primaryText)

                    Text("Quickly capture all your thoughts")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.Colors.accent.opacity(0.3), Theme.Colors.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Example Integration

struct BrainDumpIntegrationExample: View {
    @State private var showingBrainDump = false
    @State private var tasks: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Your main content here
                VStack {
                    // Quick access card at top of tasks list
                    BrainDumpQuickAccessCard(isPresented: $showingBrainDump)
                        .padding(.horizontal)

                    // Task list
                    List {
                        ForEach(tasks, id: \.self) { task in
                            Text(task)
                        }
                    }
                }

                // FAB overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BrainDumpFAB(isPresented: $showingBrainDump)
                    }
                }
            }
            .navigationTitle("Tasks")
            .sheet(isPresented: $showingBrainDump) {
                BrainDumpSheet(
                    isPresented: $showingBrainDump,
                    onTasksCreated: { createdTasks in
                        // Add to your tasks
                        tasks.append(contentsOf: createdTasks.map { $0.title })
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Preview

#Preview("FAB") {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        BrainDumpFAB(isPresented: .constant(false))
    }
}

#Preview("Quick Access Card") {
    VStack {
        BrainDumpQuickAccessCard(isPresented: .constant(false))
            .padding()
    }
    .background(Theme.Colors.background)
}

#Preview("Full Integration") {
    BrainDumpIntegrationExample()
}
