//
//  USBNotifierApp.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import SwiftUI
import UserNotifications

@main
struct USBNotifierApp: App {
    init() {
        // Check notification permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Request notification permissions if not already granted
            if settings.authorizationStatus != .authorized {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if !granted {
                        // Show dialog
                        Task { @MainActor in
                            let alert = NSAlert()
                            alert.messageText = String(localized: "dialog.notificationAccess.title")
                            alert.informativeText = String(localized: "dialog.notificationAccess.content")
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: String(localized: "dialog.notificationAccess.goToSettings"))
                            alert.addButton(withTitle: String(localized: "dialog.notificationAccess.cancel"))
                            if alert.runModal() == .alertFirstButtonReturn {
                                NSWorkspace.shared.open(URL(string:
                                        "x-apple.systempreferences:com.apple.preference.notifications")!)
                            } else {
                                exit(0)
                            }
                        }
                    }
                }
            }
        }

        USBDetector.Observable().status = true
    }

    var body: some Scene {
        MenuBarExtra("USBNotifier", systemImage: "cable.connector") {
            MenuBarView()
        }
    }
}
