//
//  VeloceWidgetsBundle.swift
//  VeloceWidgets
//
//  Widget Bundle - Multiple widgets for home screen
//  Includes Tasks, Stats, Streak, and Quick Add widgets
//

import WidgetKit
import SwiftUI

@main
struct VeloceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Task list widget
        VeloceTasksWidget()

        // Daily progress ring widget
        VeloceProgressWidget()

        // Streak flame widget
        VeloceStreakWidget()

        // AI motivation quote widget
        VeloceMotivationWidget()

        // Live Activity for Pomodoro
        if #available(iOS 16.2, *) {
            PomodoroLiveActivity()
        }
    }
}
