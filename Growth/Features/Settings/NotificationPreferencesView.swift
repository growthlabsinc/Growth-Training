//
//  NotificationPreferencesView.swift
//  Growth
//
//  Created by Assistant on current date.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("dailyReminderTimeInterval") private var dailyReminderTimeInterval: Double = 0
    
    private var dailyReminderTime: Date {
        get { 
            if dailyReminderTimeInterval == 0 {
                return Date()
            }
            return Date(timeIntervalSince1970: dailyReminderTimeInterval) 
        }
        set { dailyReminderTimeInterval = newValue.timeIntervalSince1970 }
    }
    @AppStorage("sessionReminderEnabled") private var sessionReminderEnabled = true
    @AppStorage("progressUpdateEnabled") private var progressUpdateEnabled = true
    
    @State private var reminderDate = Date()
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChangeCompat(of: notificationsEnabled) { newValue in
                        if newValue {
                            notificationService.requestAuthorization()
                        } else {
                            notificationService.disableAllNotifications()
                        }
                    }
            } header: {
                Text("GENERAL")
                    .font(AppTheme.Typography.gravitySemibold(13))
            }
            
            Section {
                Toggle("Daily Practice Reminder", isOn: $dailyReminderEnabled)
                    .disabled(!notificationsEnabled)
                
                if dailyReminderEnabled && notificationsEnabled {
                    DatePicker("Reminder Time", 
                              selection: $reminderDate,
                              displayedComponents: .hourAndMinute)
                        .onChangeCompat(of: reminderDate) { newTime in
                            dailyReminderTimeInterval = newTime.timeIntervalSince1970
                            notificationService.scheduleDailyReminder(at: newTime)
                        }
                }
                
                Toggle("Session Reminders", isOn: $sessionReminderEnabled)
                    .disabled(!notificationsEnabled)
                
                Toggle("Progress Updates", isOn: $progressUpdateEnabled)
                    .disabled(!notificationsEnabled)
            } header: {
                Text("NOTIFICATION TYPES")
                    .font(AppTheme.Typography.gravitySemibold(13))
            } footer: {
                Text("Customize which notifications you receive and when")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            reminderDate = dailyReminderTime
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        notificationService.checkAuthorizationStatus { isAuthorized in
            if !isAuthorized {
                notificationsEnabled = false
            }
        }
    }
}

#if DEBUG
struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationPreferencesView()
        }
    }
}
#endif