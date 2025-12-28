//
//  LiquidGlassQuickReference.swift
//  MyTasksAI
//
//  Quick Reference Examples for All Liquid Glass Components
//  Copy-paste these examples directly into your code
//

import SwiftUI

// MARK: - Quick Reference Examples

/*

 ╔═══════════════════════════════════════════════════════════════════╗
 ║                   LIQUID GLASS QUICK REFERENCE                    ║
 ║                  Copy-Paste Ready Code Examples                   ║
 ╚═══════════════════════════════════════════════════════════════════╝

 TABLE OF CONTENTS:
 1. Buttons
 2. Cards
 3. Input Fields
 4. Lists & Sections
 5. Empty States
 6. Settings
 7. Complete Screens

 ═══════════════════════════════════════════════════════════════════

 1. BUTTONS
 ═══════════════════════════════════════════════════════════════════
 
 // Primary CTA Button
 LiquidGlassButton.primary("Get Started", icon: "arrow.right") {
     // Your action
 }
 
 // Secondary Button
 LiquidGlassButton.secondary("Cancel") {
     // Your action
 }
 
 // Success Button
 LiquidGlassButton.success("Enabled", icon: "checkmark.circle.fill") {
     // Your action
 }
 
 // Icon Button
 LiquidGlassButton.icon(systemName: "star.fill", size: 44) {
     // Your action
 }
 
 // Multiple Icon Buttons with Morphing
 GlassEffectContainer(spacing: 30) {
     HStack(spacing: 30) {
         LiquidGlassButton.icon(systemName: "heart.fill", action: {})
         LiquidGlassButton.icon(systemName: "bookmark.fill", action: {})
         LiquidGlassButton.icon(systemName: "star.fill", action: {})
     }
 }

 ═══════════════════════════════════════════════════════════════════

 2. CARDS
 ═══════════════════════════════════════════════════════════════════
 
 // Standard Glass Card
 LiquidGlassCard {
     VStack(alignment: .leading, spacing: 12) {
         Text("Card Title")
             .font(.title3.bold())
             .foregroundStyle(.white)
         
         Text("Card description goes here")
             .font(.body)
             .foregroundStyle(.white.opacity(0.7))
     }
 }
 
 // Tinted Card (Purple)
 LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple) {
     // Your content
 }
 
 // Tinted Card (Cyan - Primary Actions)
 LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan) {
     // Your content
 }
 
 // Tinted Card (Green - Success)
 LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen) {
     // Your content
 }
 
 // Tinted Card (Gold - Goals/Achievements)
 LiquidGlassCard(tint: LiquidGlassDesignSystem.VibrantAccents.solarGold) {
     // Your content
 }
 
 // Interactive Card (responds to touch)
 LiquidGlassCard(cornerRadius: 20, tint: nil, interactive: true) {
     // Your content
 }
 
 // Custom Corner Radius
 LiquidGlassCard(cornerRadius: 24) {
     // Your content
 }

 ═══════════════════════════════════════════════════════════════════

 3. INPUT FIELDS
 ═══════════════════════════════════════════════════════════════════
 
 // Text Field
 @State private var text = ""
 @FocusState private var isFocused: Bool
 
 LiquidGlassTextField(
     placeholder: "Enter text...",
     text: $text,
     isFocused: $isFocused,
     onSubmit: {
         print("Submitted: \(text)")
     }
 )
 
 // Password Field
 @State private var password = ""
 
 LiquidGlassSecureField(
     placeholder: "Password",
     text: $password,
     isFocused: isFocused,
     onSubmit: {
         // Handle password submission
     }
 )
 
 // Multiple Fields in Form
 VStack(spacing: 20) {
     LiquidGlassTextField(
         placeholder: "Email",
         text: $email,
         isFocused: $emailFocused,
         onSubmit: { passwordFocused = true }
     )
     
     LiquidGlassSecureField(
         placeholder: "Password",
         text: $password,
         isFocused: passwordFocused,
         onSubmit: { submitForm() }
     )
 }

 ═══════════════════════════════════════════════════════════════════

 4. LISTS & SECTIONS
 ═══════════════════════════════════════════════════════════════════
 
 // Section Header (Simple)
 LiquidGlassSectionHeader(
     title: "Recent Activity",
     icon: "clock.fill"
 )
 
 // Section Header with Action
 LiquidGlassSectionHeader(
     title: "Tasks",
     icon: "checkmark.circle.fill",
     action: {
         // Navigate to all tasks
     }
 )
 
 // Collapsible Task Section
 @State private var isExpanded = true
 
 LiquidGlassTaskSection(
     title: "Today",
     taskCount: 5,
     icon: "calendar",
     accentColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
     isExpanded: $isExpanded,
     onToggle: {
         withAnimation(LiquidGlassDesignSystem.Springs.ui) {
             isExpanded.toggle()
         }
     }
 )
 
 // Task Card
 LiquidGlassTaskCard(
     task: task,
     onTap: {
         selectedTask = task
     },
     onComplete: {
         toggleTaskCompletion(task)
     }
 )
 
 // Pills / Badges
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

 ═══════════════════════════════════════════════════════════════════

 5. EMPTY STATES
 ═══════════════════════════════════════════════════════════════════
 
 // Empty State without Action
 LiquidGlassEmptyState(
     icon: "checkmark.circle",
     title: "All Done!",
     message: "You've completed all your tasks for today"
 )
 
 // Empty State with Action
 LiquidGlassEmptyState(
     icon: "tray",
     title: "No Tasks Yet",
     message: "Start your productivity journey by adding your first task",
     actionTitle: "Add Task",
     action: {
         showAddTaskSheet = true
     }
 )
 
 // Empty State in List
 if tasks.isEmpty {
     LiquidGlassEmptyState(
         icon: "calendar.badge.exclamationmark",
         title: "Nothing Scheduled",
         message: "Schedule tasks to plan your week better",
         actionTitle: "Schedule Task",
         action: {
             showScheduler = true
         }
     )
 }

 ═══════════════════════════════════════════════════════════════════

 6. SETTINGS
 ═══════════════════════════════════════════════════════════════════
 
 // Toggle Row
 @State private var notificationsEnabled = true
 
 LiquidGlassToggleRow(
     title: "Notifications",
     subtitle: "Get reminders for tasks and deadlines",
     icon: "bell.fill",
     iconColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
     isOn: $notificationsEnabled
 )
 
 // Multiple Toggle Rows
 VStack(spacing: 16) {
     LiquidGlassToggleRow(
         title: "Notifications",
         subtitle: "Get reminders for tasks",
         icon: "bell.fill",
         iconColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
         isOn: $notificationsEnabled
     )
     
     LiquidGlassToggleRow(
         title: "Focus Mode",
         subtitle: "Block distractions during work",
         icon: "brain.head.profile",
         iconColor: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
         isOn: $focusModeEnabled
     )
     
     LiquidGlassToggleRow(
         title: "Dark Mode",
         subtitle: "Always use dark theme",
         icon: "moon.fill",
         iconColor: LiquidGlassDesignSystem.VibrantAccents.cosmicBlue,
         isOn: $darkModeEnabled
     )
 }

 ═══════════════════════════════════════════════════════════════════

 7. COMPLETE SCREENS
 ═══════════════════════════════════════════════════════════════════
 
 // EXAMPLE 1: Simple Task List
 
 ScrollView {
     VStack(spacing: 16) {
         LiquidGlassTaskSection(
             title: "Today",
             taskCount: todayTasks.count,
             icon: "calendar",
             accentColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
             isExpanded: $isTodayExpanded,
             onToggle: { isTodayExpanded.toggle() }
         )
         
         if isTodayExpanded {
             ForEach(todayTasks) { task in
                 LiquidGlassTaskCard(
                     task: task,
                     onTap: { selectedTask = task },
                     onComplete: { toggleCompletion(task) }
                 )
             }
         }
     }
     .padding()
 }
 
 // EXAMPLE 2: Settings Screen
 
 ScrollView {
     VStack(spacing: 24) {
         LiquidGlassSectionHeader(title: "Notifications", icon: "bell.fill")
         
         VStack(spacing: 16) {
             LiquidGlassToggleRow(
                 title: "Task Reminders",
                 subtitle: "Get notified about upcoming tasks",
                 icon: "clock.badge.fill",
                 iconColor: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                 isOn: $taskReminders
             )
             
             LiquidGlassToggleRow(
                 title: "Goal Updates",
                 subtitle: "Weekly progress summaries",
                 icon: "target",
                 iconColor: LiquidGlassDesignSystem.VibrantAccents.solarGold,
                 isOn: $goalUpdates
             )
         }
         
         LiquidGlassSectionHeader(title: "Appearance", icon: "paintbrush.fill")
         
         VStack(spacing: 16) {
             LiquidGlassToggleRow(
                 title: "Dark Mode",
                 subtitle: "Always use dark theme",
                 icon: "moon.fill",
                 iconColor: LiquidGlassDesignSystem.VibrantAccents.cosmicBlue,
                 isOn: $darkMode
             )
         }
     }
     .padding()
 }
 
 // EXAMPLE 3: Authentication Flow
 
 LiquidGlassSignInView(
     onSignIn: { email, password in
         try await authService.signIn(email: email, password: password)
     },
     onSignUpTapped: {
         showSignUp = true
     },
     onForgotPassword: {
         showForgotPassword = true
     }
 )
 
 // Or Sign Up
 LiquidGlassSignUpView(
     onSignUp: { name, email, password in
         try await authService.signUp(name: name, email: email, password: password)
     },
     onSignInTapped: {
         showSignIn = true
     }
 )
 
 // EXAMPLE 4: Goal Card
 
 LiquidGlassCard(
     cornerRadius: 20,
     tint: LiquidGlassDesignSystem.VibrantAccents.solarGold
 ) {
     VStack(alignment: .leading, spacing: 12) {
         HStack {
             Text("Run 5K")
                 .font(.system(size: 20, weight: .semibold))
                 .foregroundStyle(.white)
             
             Spacer()
             
             Text("75%")
                 .font(.system(size: 16, weight: .bold))
                 .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.solarGold)
         }
         
         Text("Complete a 5 kilometer run by end of month")
             .font(.system(size: 15))
             .foregroundStyle(.white.opacity(0.7))
             .lineLimit(2)
         
         // Progress bar
         GeometryReader { geometry in
             ZStack(alignment: .leading) {
                 Capsule()
                     .fill(.white.opacity(0.1))
                     .frame(height: 8)
                 
                 Capsule()
                     .fill(LiquidGlassDesignSystem.VibrantAccents.solarGold)
                     .frame(width: geometry.size.width * 0.75, height: 8)
             }
         }
         .frame(height: 8)
     }
 }

 ═══════════════════════════════════════════════════════════════════

 PREMIUM EFFECTS
 ═══════════════════════════════════════════════════════════════════
 
 // Add Iridescent Glow to Important Elements
 
 LiquidGlassButton.primary("Launch", icon: "rocket.fill") {
     // action
 }
 .premiumGlowCapsule(
     style: .iridescent,
     intensity: .medium,
     animated: true
 )
 
 // Subtle Glow
 SomeView()
     .premiumGlowCapsule(
         style: .subtle,
         intensity: .whisper,
         animated: false
     )
 
 // Energetic Pulsing Glow
 SomeView()
     .premiumGlowCapsule(
         style: .energetic,
         intensity: .bold,
         animated: true
     )

 ═══════════════════════════════════════════════════════════════════

 QUICK ACTION MENU
 ═══════════════════════════════════════════════════════════════════
 
 @State private var showQuickActions = false
 
 // Add to your view:
 .overlay {
     LiquidGlassQuickActionMenu(
         isPresented: showQuickActions,
         onDismiss: { showQuickActions = false },
         onAddTask: {
             showAddTaskSheet = true
         },
         onAddGoal: {
             showAddGoalSheet = true
         },
         onStartFocus: {
             selectedTab = .flow
         },
         onBrainDump: {
             showBrainDumpSheet = true
         }
     )
 }
 
 // Trigger with a button:
 LiquidGlassButton.icon(systemName: "plus") {
     showQuickActions = true
 }

 ═══════════════════════════════════════════════════════════════════

 COLOR PALETTE
 ═══════════════════════════════════════════════════════════════════
 
 // Electric Cyan - Primary Actions
 LiquidGlassDesignSystem.VibrantAccents.electricCyan
 
 // Plasma Purple - AI Features
 LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
 
 // Aurora Green - Success States
 LiquidGlassDesignSystem.VibrantAccents.auroraGreen
 
 // Solar Gold - Goals & Achievements
 LiquidGlassDesignSystem.VibrantAccents.solarGold
 
 // Nebula Pink - Warnings & Errors
 LiquidGlassDesignSystem.VibrantAccents.nebulaPink
 
 // Cosmic Blue - Info & Highlights
 LiquidGlassDesignSystem.VibrantAccents.cosmicBlue

 ═══════════════════════════════════════════════════════════════════

 ANIMATION SPRINGS
 ═══════════════════════════════════════════════════════════════════
 
 // Ultra-fast UI interactions (buttons, toggles)
 withAnimation(LiquidGlassDesignSystem.Springs.ui) {
     // Your state change
 }
 
 // Page transitions
 withAnimation(LiquidGlassDesignSystem.Springs.page) {
     // Your state change
 }
 
 // Sheet/modal presentations
 withAnimation(LiquidGlassDesignSystem.Springs.focus) {
     // Your state change
 }
 
 // Glass morphing effects
 withAnimation(LiquidGlassDesignSystem.Springs.morph) {
     // Your state change
 }

 ═══════════════════════════════════════════════════════════════════

 MORPHING GLASS CONTAINER
 ═══════════════════════════════════════════════════════════════════
 
 // For glass elements that should blend when close together
 
 GlassEffectContainer(spacing: 40) {
     HStack(spacing: 40) {
         // These will morph together when within 40pt
         Button1().glassEffect()
         Button2().glassEffect()
         Button3().glassEffect()
     }
 }
 
 // Adjust spacing for different effects:
 
 // Tight spacing (blend easily)
 GlassEffectContainer(spacing: 20) { }
 
 // Default spacing
 GlassEffectContainer(spacing: 40) { }
 
 // Wide spacing (rarely blend)
 GlassEffectContainer(spacing: 60) { }

 ═══════════════════════════════════════════════════════════════════

*/

// MARK: - End of Quick Reference
