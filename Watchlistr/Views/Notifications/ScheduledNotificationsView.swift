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
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var movieNotifications: [UNNotificationRequest] = []
    @State private var tvShowNotifications: [UNNotificationRequest] = []
    @State private var oldNotifications: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isSortedByDate: Bool = false

    var username: String
    
    var body: some View {
        Group {
            if movieNotifications.isEmpty && tvShowNotifications.isEmpty && oldNotifications.isEmpty && deliveredNotifications.isEmpty {
                EmptyPlaceholderView(text: "Your notifications will appear here when setting reminders for movies or shows.", image: Image(systemName: "bell.slash"))
            } else {
                List {
                    if !movieNotifications.isEmpty {
                        Section(header: Image(systemName: "film")) {
                            ForEach(movieNotifications, id: \.identifier) { notification in
                                NotificationRow(notification: notification, formatter: formatter, deleteNotification: deleteNotification, loadNotifications: loadNotifications)
                            }
                        }
                    }
                    
                    if !tvShowNotifications.isEmpty {
                        Section(header: Image(systemName: "tv")) {
                            ForEach(tvShowNotifications, id: \.identifier) { notification in
                                NotificationRow(notification: notification, formatter: formatter, deleteNotification: deleteNotification, loadNotifications: loadNotifications)
                            }
                        }
                    }
                    
                    if !oldNotifications.isEmpty {
                        Section(header: Text("Other Notifications")) {
                            ForEach(oldNotifications, id: \.identifier) { notification in
                                NotificationRow(notification: notification, formatter: formatter, deleteNotification: deleteNotification, loadNotifications: loadNotifications)
                            }
                        }
                    }
                    
                    if !deliveredNotifications.isEmpty {
                        Section(header: Text("Delivered Notifications")) {
                            ForEach(deliveredNotifications, id: \.request.identifier) { notification in
                                DeliveredNotificationRow(notification: notification, formatter: formatter, deleteNotification: deleteNotification, loadNotifications: loadNotifications)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarItems(trailing: Button(action: {
            isSortedByDate.toggle()
            loadNotifications()
        }) {
            Image(systemName: isSortedByDate ? "calendar" : "calendar.badge.plus")
        })
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNotifications()
        }
    }

    private func loadNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let filteredRequests = requests.filter {
                $0.identifier.contains(username) &&
                ($0.identifier.hasPrefix("reminder_") || $0.identifier.hasPrefix("custom_reminder_"))
            }
            
            if isSortedByDate {
                self.movieNotifications = sortNotificationsByDate(filteredRequests.filter { $0.identifier.contains("movie_") })
                self.tvShowNotifications = sortNotificationsByDate(filteredRequests.filter { $0.identifier.contains("tv_show_") })
            } else {
                self.movieNotifications = filteredRequests.filter { $0.identifier.contains("movie_") }
                self.tvShowNotifications = filteredRequests.filter { $0.identifier.contains("tv_show_") }
            }
            
            let movieAndTVShowIdentifiers = Set(self.movieNotifications.map { $0.identifier } + self.tvShowNotifications.map { $0.identifier })
            self.oldNotifications = requests.filter {
                $0.identifier.contains(username) && !movieAndTVShowIdentifiers.contains($0.identifier)
            }
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            self.deliveredNotifications = notifications.filter {
                $0.request.identifier.contains(username)
            }
            
        }
    }
    
    private func sortNotificationsByDate(_ notifications: [UNNotificationRequest]) -> [UNNotificationRequest] {
        return notifications.sorted {
            guard let date1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                  let date2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return false }
            return date1 < date2
        }
    }
    
    private func deleteNotification(with identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        
        loadNotifications()
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct NotificationRow: View {
    let notification: UNNotificationRequest
    let formatter: DateFormatter
    let deleteNotification: (String) -> Void
    let loadNotifications: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(notification.content.title)
                    .font(.headline)
                Spacer()
                if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                   let fireDate = trigger.nextTriggerDate() {
                    Text("\(formatter.string(from: fireDate))")
                        .font(.footnote)
                        .foregroundColor(.blue)
                    +
                    Text(" (\(timeLeft(for: notification)))")
                        .font(.footnote)
                        .foregroundColor(.indigo)
                }
            }
            Text(notification.content.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteNotification(notification.identifier)
                loadNotifications()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
    
    private func timeLeft(for notification: UNNotificationRequest) -> String {
        guard let trigger = notification.trigger as? UNCalendarNotificationTrigger,
              let fireDate = trigger.nextTriggerDate() else {
            return "N/A"
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: fireDate)
        
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        var timeLeft = ""
        if days > 0 {
            timeLeft += "\(days)d "
        }
        if hours > 0 || days > 0 {
            timeLeft += "\(hours)h "
        }
        if minutes > 0 || hours > 0 || days > 0 {
            timeLeft += "\(minutes)m"
        }
        return timeLeft
    }
}

struct DeliveredNotificationRow: View {
    let notification: UNNotification
    let formatter: DateFormatter
    let deleteNotification: (String) -> Void
    let loadNotifications: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(notification.request.content.title)
                    .font(.headline)
                Spacer()
                Text(formatter.string(from: notification.date))
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            Text(notification.request.content.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteNotification(notification.request.identifier)
                loadNotifications()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct ScheduledNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduledNotificationsView(username: "devzano")
        }
    }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    override private init() {}

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
