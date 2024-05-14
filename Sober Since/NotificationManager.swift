//
//  NotificationManager.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager {
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleMilestoneNotifications()
            }
        }
    }
    
    static func scheduleMilestoneNotifications() {
        guard let notificationsEnabled = UserDefaults.standard.value(forKey: "notificationsEnabled") as? Bool, notificationsEnabled else { return }
        
        let sobrietyStartTimestamp = UserDefaults.standard.double(forKey: "sobrietyStartTimestamp")
        let sobrietyStartDate = Date(timeIntervalSince1970: sobrietyStartTimestamp)
        let now = Date()
        
        let calendar = Calendar.current

        // Schedule notifications for the first 30 days every 5 days
        for day in stride(from: 5, through: 30, by: 5) {
            if let milestoneDate = calendar.date(byAdding: .day, value: day, to: sobrietyStartDate), milestoneDate > now {
                scheduleNotification(for: milestoneDate, message: "Congratulations on \(day) days of sobriety! 🥳")
            }
        }

        // Schedule notifications every month after the first 30 days
        var monthCount = 1
        while let milestoneDate = calendar.date(byAdding: .month, value: monthCount, to: sobrietyStartDate), milestoneDate > now {
            scheduleNotification(for: milestoneDate, message: "Congratulations on \(monthCount) month(s) of sobriety! 🥳")
            monthCount += 1
        }
    }
    
    static func scheduleNotification(for date: Date, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Milestone Achieved"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
