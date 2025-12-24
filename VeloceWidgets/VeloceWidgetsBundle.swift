//
//  VeloceWidgetsBundle.swift
//  VeloceWidgets
//
//  Widget Bundle - Living Cosmos Design System
//  Complete widget suite for home screen experience
//  Includes Tasks, Focus, XP, Calendar, Streak, Quick Add & more
//

import WidgetKit
import SwiftUI

@main
struct VeloceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // MARK: - Core Widgets

        // Task list widget (Small, Medium, Large)
        VeloceTasksWidget()

        // Focus timer widget (Small)
        VeloceFocusWidget()

        // XP/Level progress widget (Small, Medium)
        VeloceXPWidget()

        // Calendar widget (Small, Medium, Large)
        VeloceCalendarWidget()

        // MARK: - Gamification Widgets

        // Streak flame widget (Small, Medium)
        VeloceStreakWidget()

        // Daily progress ring widget (Small + Lock Screen)
        VeloceProgressWidget()

        // MARK: - Quick Actions

        // Quick add task widget (Small + Lock Screen)
        VeloceQuickAddWidget()

        // MARK: - Motivation

        // AI motivation quote widget (Medium, Large)
        VeloceMotivationWidget()

        // MARK: - Live Activities

        // Live Activity for Focus Timer
        if #available(iOS 16.2, *) {
            PomodoroLiveActivity()
        }
    }
}
