//
//  LiquidGlassShowcase.swift
//  MyTasksAI
//
//  Complete showcase of all Liquid Glass components
//  Use this as a visual reference and component gallery
//

import SwiftUI

struct LiquidGlassShowcase: View {
    @State private var selectedTab = 0
    @State private var text = ""
    @State private var password = ""
    @FocusState private var isFocused: Bool
    @State private var toggleState1 = true
    @State private var toggleState2 = false
    @State private var showQuickActions = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Buttons
                buttonsShowcase
                    .tag(0)
                
                // Tab 2: Cards & Containers
                cardsShowcase
                    .tag(1)
                
                // Tab 3: Input Elements
                inputsShowcase
                    .tag(2)
                
                // Tab 4: Lists & Sections
                listsShowcase
                    .tag(3)
                
                // Tab 5: Complete Flows
                flowsShowcase
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(cosmicBackground)
            .navigationTitle("Liquid Glass Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Tab \(selectedTab + 1)/5")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Buttons Showcase
    
    private var buttonsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Buttons", icon: "button.programmable")
                
                VStack(spacing: 16) {
                    // Primary Button
                    LiquidGlassButton.primary("Primary Action", icon: "arrow.right", action: {})
                    
                    // Secondary Button
                    LiquidGlassButton.secondary("Secondary Action", icon: "star", action: {})
                    
                    // Success Button
                    LiquidGlassButton.success("Success State", icon: "checkmark.circle.fill", action: {})
                    
                    // Icon Buttons
                    HStack(spacing: 16) {
                        LiquidGlassButton.icon(systemName: "heart.fill", action: {})
                        LiquidGlassButton.icon(systemName: "bookmark.fill", action: {})
                        LiquidGlassButton.icon(systemName: "star.fill", action: {})
                        LiquidGlassButton.icon(systemName: "bell.fill", action: {})
                    }
                    
                    // Morphing Icon Buttons (in container)
                    LiquidGlassContainer(spacing: 30) {
                        HStack(spacing: 30) {
                            LiquidGlassButton.icon(systemName: "play.fill", action: {})
                            LiquidGlassButton.icon(systemName: "pause.fill", action: {})
                            LiquidGlassButton.icon(systemName: "stop.fill", action: {})
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Cards Showcase
    
    private var cardsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Cards & Containers", icon: "rectangle.stack")
                
                VStack(spacing: 20) {
                    // Standard Glass Card
                    LiquidGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Standard Card")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("A beautiful glass card with native iOS 26 liquid glass effect.")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    // Tinted Purple Card
                    LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) {
                        cardContent(
                            title: "Purple Tinted",
                            description: "Subtle plasma purple tint for AI features"
                        )
                    }
                    
                    // Tinted Cyan Card
                    LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan) {
                        cardContent(
                            title: "Cyan Tinted",
                            description: "Electric cyan for primary actions"
                        )
                    }
                    
                    // Tinted Green Card (Success)
                    LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen) {
                        cardContent(
                            title: "Success State",
                            description: "Aurora green for completed items"
                        )
                    }
                    
                    // Interactive Card
                    LiquidGlassCard(interactive: true) {
                        cardContent(
                            title: "Interactive Card",
                            description: "Touch-responsive glass effect"
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Inputs Showcase
    
    private var inputsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Input Elements", icon: "keyboard")
                
                VStack(spacing: 20) {
                    // Text Field
                    LiquidGlassTextField(
                        placeholder: "Enter text...",
                        text: $text,
                        isFocused: $isFocused,
                        onSubmit: {
                            print("Submitted: \(text)")
                        }
                    )
                    
                    // Secure Field
                    LiquidGlassSecureField(
                        placeholder: "Enter password...",
                        text: $password,
                        isFocused: false,
                        onSubmit: {
                            print("Password submitted")
                        }
                    )
                    
                    // Pills / Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pills & Tags")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 12) {
                            LiquidGlassPill(
                                text: "Work",
                                icon: "briefcase.fill",
                                color: LiquidGlassDesignSystem.VibrantAccents.electricCyan
                            )
                            LiquidGlassPill(
                                text: "Urgent",
                                icon: "exclamationmark.triangle.fill",
                                color: LiquidGlassDesignSystem.VibrantAccents.nebulaPink
                            )
                            LiquidGlassPill(
                                text: "Goal",
                                icon: "target",
                                color: LiquidGlassDesignSystem.VibrantAccents.solarGold
                            )
                        }
                    }
                    
                    // Toggle Rows
                    VStack(spacing: 16) {
                        Text("Toggle Rows")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        LiquidGlassToggleRow(
                            title: "Notifications",
                            subtitle: "Get reminders for tasks",
                            icon: "bell.fill",
                            iconColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                            isOn: $toggleState1
                        )
                        
                        LiquidGlassToggleRow(
                            title: "Focus Mode",
                            subtitle: "Block distractions",
                            icon: "brain.head.profile",
                            iconColor: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                            isOn: $toggleState2
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Lists Showcase
    
    private var listsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Lists & Sections", icon: "list.bullet")
                
                VStack(spacing: 16) {
                    // Section Headers
                    LiquidGlassTaskSection(
                        title: "Today",
                        taskCount: 5,
                        icon: "calendar",
                        accentColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                        isExpanded: .constant(true),
                        onToggle: {}
                    )
                    
                    LiquidGlassTaskSection(
                        title: "Tomorrow",
                        taskCount: 3,
                        icon: "clock.fill",
                        accentColor: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                        isExpanded: .constant(false),
                        onToggle: {}
                    )
                    
                    // Sample Task Cards
                    VStack(spacing: 12) {
                        Text("Task Cards")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        LiquidGlassTaskCard(
                            task: TaskItem(
                                id: UUID(),
                                title: "Complete project proposal",
                                isCompleted: false,
                                priority: 3
                            ),
                            onTap: {},
                            onComplete: {}
                        )
                        
                        LiquidGlassTaskCard(
                            task: TaskItem(
                                id: UUID(),
                                title: "Review pull requests",
                                isCompleted: true,
                                priority: 2
                            ),
                            onTap: {},
                            onComplete: {}
                        )
                    }
                    
                    // Section Header (Simple)
                    LiquidGlassSectionHeader(
                        title: "Account",
                        icon: "person.fill",
                        action: {}
                    )
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Flows Showcase
    
    private var flowsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Complete Flows", icon: "square.stack.3d.up")
                
                VStack(spacing: 24) {
                    // Empty State
                    LiquidGlassEmptyState(
                        icon: "checkmark.circle",
                        title: "All Caught Up!",
                        message: "You've completed all your tasks for today. Great work!",
                        actionTitle: "Add New Task",
                        action: {}
                    )
                    
                    // Premium Glows Demo
                    VStack(spacing: 20) {
                        Text("Premium Glows")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        // Subtle glow
                        Text("Whisper Glow")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(16)
                            .glassEffect(.regular, in: Capsule())
                            .premiumGlowCapsule(
                                style: .subtle,
                                intensity: .whisper,
                                animated: false
                            )
                        
                        // Iridescent glow
                        Text("Iridescent Glow")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(16)
                            .glassEffect(.regular, in: Capsule())
                            .premiumGlowCapsule(
                                style: .iridescent,
                                intensity: .medium,
                                animated: true
                            )
                        
                        // Energetic glow
                        Text("Energetic Glow")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(16)
                            .glassEffect(.regular, in: Capsule())
                            .premiumGlowCapsule(
                                style: .energetic,
                                intensity: .bold,
                                animated: true
                            )
                    }
                    
                    // Quick Actions Button
                    Button {
                        showQuickActions = true
                    } label: {
                        Text("Show Quick Actions")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                    }
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
        .overlay {
            LiquidGlassQuickActionMenu(
                isPresented: showQuickActions,
                onDismiss: { showQuickActions = false },
                onAddTask: {},
                onAddGoal: {},
                onStartFocus: {},
                onBrainDump: {}
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private func cardContent(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    private var cosmicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.02),
                    Color(red: 0.02, green: 0.02, blue: 0.035),
                    Color(red: 0.03, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Nebula accents
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.1),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassShowcase()
}

// MARK: - Quick Test Views

#Preview("All Buttons") {
    VStack(spacing: 20) {
        LiquidGlassButton.primary("Primary", icon: "star.fill", action: {})
        LiquidGlassButton.secondary("Secondary", action: {})
        LiquidGlassButton.success("Success", action: {})
        
        HStack {
            LiquidGlassButton.icon(systemName: "heart.fill", action: {})
            LiquidGlassButton.icon(systemName: "bookmark.fill", action: {})
            LiquidGlassButton.icon(systemName: "star.fill", action: {})
        }
    }
    .padding(40)
    .background(Color(red: 0.02, green: 0.02, blue: 0.04))
}

#Preview("All Cards") {
    ScrollView {
        VStack(spacing: 20) {
            LiquidGlassCard {
                Text("Standard Glass Card")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            
            LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) {
                Text("Purple Tinted Card")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            
            LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen) {
                Text("Green Success Card")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
        }
        .padding(32)
    }
    .background(Color(red: 0.02, green: 0.02, blue: 0.04))
}
