//
//  USBNotifierApp.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import SwiftUI

@main
struct USBNotifierApp: App {
    init() {
        if Storage.shared.autostart {
            USBDetector.shared.startDetection()
        }
    }

    var body: some Scene {
        MenuBarExtra("USBNotifier", systemImage: "cable.connector") {
            MenuBarView()
        }
    }
}
