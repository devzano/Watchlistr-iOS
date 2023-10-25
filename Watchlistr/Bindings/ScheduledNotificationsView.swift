//
//  ScheduledNotificationsView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/21/23.
//

import SwiftUI
import UserNotifications

func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            showError(message: "Error requesting authorization: \(error)")
            completion(false)
            return
        }
        completion(granted)
    }
}

func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        completion(requests)
    }
}

struct ScheduledNotificationsView: View {
    @EnvironmentObject var vm: AuthViewModel
    @State private var notifications: [UNNotificationRequest] = []
    var username: String
    
    var body: some View {
        List(notifications, id: \.identifier) { notification in
            VStack(alignment: .leading) {
                HStack {
                    Text(notification.content.title)
                        .font(.headline)
                    Spacer()
                    if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                       let fireDate = trigger.nextTriggerDate() {
                        Text(formatter.string(from: fireDate))
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }

                Text(notification.content.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .swipeActions {
                Button(role: .destructive) {
                    deleteNotification(with: notification.identifier)
                    loadNotifications()
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadNotifications)
    }

    private func loadNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            self.notifications = requests.filter {
                $0.identifier.contains(username) &&
                ($0.identifier.hasPrefix("reminder_") || $0.identifier.hasPrefix("custom_reminder_"))
            }
        }
    }
    
    private func deleteNotification(with identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ScheduledNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduledNotificationsView(username: "devzano")
        }
    }
}
