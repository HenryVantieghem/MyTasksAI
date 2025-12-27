//
//  VeloceCommands.swift
//  Veloce
//
//  iPadOS 26 Menu Bar Commands and Keyboard Navigation
//  Provides keyboard shortcuts and menu bar integration for iPad
//

import SwiftUI

// MARK: - Veloce Commands

struct VeloceCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // MARK: - Task Commands

        CommandMenu("Tasks") {
            Button("New Task") {
                NotificationCenter.default.post(name: .newTaskCommand, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Brain Dump") {
                NotificationCenter.default.post(name: .brainDumpCommand, object: nil)
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])

            Divider()

            Button("Complete Selected Task") {
                NotificationCenter.default.post(name: .completeTaskCommand, object: nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            Button("Delete Selected Task") {
                NotificationCenter.default.post(name: .deleteTaskCommand, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [.command])

            Divider()

            Button("Focus Mode") {
                NotificationCenter.default.post(name: .focusModeCommand, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }

        // MARK: - Navigation Commands

        CommandMenu("Navigate") {
            Button("Tasks") {
                NotificationCenter.default.post(name: .navigateToTabCommand, object: AppTab.tasks)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Plan") {
                NotificationCenter.default.post(name: .navigateToTabCommand, object: AppTab.plan)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Grow") {
                NotificationCenter.default.post(name: .navigateToTabCommand, object: AppTab.grow)
            }
            .keyboardShortcut("3", modifiers: [.command])

            Button("Flow") {
                NotificationCenter.default.post(name: .navigateToTabCommand, object: AppTab.flow)
            }
            .keyboardShortcut("4", modifiers: [.command])

            Button("Journal") {
                NotificationCenter.default.post(name: .navigateToTabCommand, object: AppTab.journal)
            }
            .keyboardShortcut("5", modifiers: [.command])

            Divider()

            Button("Search Tasks") {
                NotificationCenter.default.post(name: .searchCommand, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command])
        }

        // MARK: - View Commands

        CommandMenu("View") {
            Button("Toggle View Mode") {
                NotificationCenter.default.post(name: .toggleViewModeCommand, object: nil)
            }
            .keyboardShortcut("l", modifiers: [.command])

            Divider()

            Button("Today") {
                NotificationCenter.default.post(name: .goToTodayCommand, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])

            Button("Previous Day") {
                NotificationCenter.default.post(name: .previousDayCommand, object: nil)
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command])

            Button("Next Day") {
                NotificationCenter.default.post(name: .nextDayCommand, object: nil)
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command])
        }
    }
}

// MARK: - Command Notification Names

extension Notification.Name {
    // Task commands
    static let newTaskCommand = Notification.Name("com.veloce.newTaskCommand")
    static let brainDumpCommand = Notification.Name("com.veloce.brainDumpCommand")
    static let completeTaskCommand = Notification.Name("com.veloce.completeTaskCommand")
    static let deleteTaskCommand = Notification.Name("com.veloce.deleteTaskCommand")
    static let focusModeCommand = Notification.Name("com.veloce.focusModeCommand")

    // Navigation commands
    static let navigateToTabCommand = Notification.Name("com.veloce.navigateToTabCommand")
    static let searchCommand = Notification.Name("com.veloce.searchCommand")

    // View commands
    static let toggleViewModeCommand = Notification.Name("com.veloce.toggleViewModeCommand")
    static let goToTodayCommand = Notification.Name("com.veloce.goToTodayCommand")
    static let previousDayCommand = Notification.Name("com.veloce.previousDayCommand")
    static let nextDayCommand = Notification.Name("com.veloce.nextDayCommand")
}

// MARK: - Command Handler View Modifier

struct CommandHandlerModifier: ViewModifier {
    @Binding var selectedTab: AppTab
    var onNewTask: () -> Void
    var onBrainDump: (() -> Void)?
    var onSearch: (() -> Void)?
    var onFocusMode: (() -> Void)?
    var onToggleViewMode: (() -> Void)?
    var onGoToToday: (() -> Void)?
    var onPreviousDay: (() -> Void)?
    var onNextDay: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .newTaskCommand)) { _ in
                onNewTask()
            }
            .onReceive(NotificationCenter.default.publisher(for: .brainDumpCommand)) { _ in
                onBrainDump?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTabCommand)) { notification in
                if let tab = notification.object as? AppTab {
                    withAnimation {
                        selectedTab = tab
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .searchCommand)) { _ in
                onSearch?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusModeCommand)) { _ in
                onFocusMode?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleViewModeCommand)) { _ in
                onToggleViewMode?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .goToTodayCommand)) { _ in
                onGoToToday?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .previousDayCommand)) { _ in
                onPreviousDay?()
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextDayCommand)) { _ in
                onNextDay?()
            }
    }
}

extension View {
    func handleCommands(
        selectedTab: Binding<AppTab>,
        onNewTask: @escaping () -> Void,
        onBrainDump: (() -> Void)? = nil,
        onSearch: (() -> Void)? = nil,
        onFocusMode: (() -> Void)? = nil,
        onToggleViewMode: (() -> Void)? = nil,
        onGoToToday: (() -> Void)? = nil,
        onPreviousDay: (() -> Void)? = nil,
        onNextDay: (() -> Void)? = nil
    ) -> some View {
        modifier(CommandHandlerModifier(
            selectedTab: selectedTab,
            onNewTask: onNewTask,
            onBrainDump: onBrainDump,
            onSearch: onSearch,
            onFocusMode: onFocusMode,
            onToggleViewMode: onToggleViewMode,
            onGoToToday: onGoToToday,
            onPreviousDay: onPreviousDay,
            onNextDay: onNextDay
        ))
    }
}

// MARK: - Keyboard Focus Modifier

struct KeyboardFocusableModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onEnter: () -> Void
    let onSpace: () -> Void

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onKeyPress(.upArrow) {
                onUpArrow()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDownArrow()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter()
                return .handled
            }
            .onKeyPress(.space) {
                onSpace()
                return .handled
            }
    }
}

extension View {
    func keyboardNavigable(
        onUpArrow: @escaping () -> Void = {},
        onDownArrow: @escaping () -> Void = {},
        onEnter: @escaping () -> Void = {},
        onSpace: @escaping () -> Void = {}
    ) -> some View {
        modifier(KeyboardFocusableModifier(
            onUpArrow: onUpArrow,
            onDownArrow: onDownArrow,
            onEnter: onEnter,
            onSpace: onSpace
        ))
    }
}
