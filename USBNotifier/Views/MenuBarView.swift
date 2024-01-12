//
//  MenuBarView.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var storage = Storage.Observable()
    @ObservedObject var autostart = LaunchAtStartup.Observable()

    @State private var possibleDetectionDelays = [1, 5, 10, 60]
    @ObservedObject private var detectorStatus = USBDetectorStatus.shared

    var body: some View {
        VStack {
            Text(String(localized: "usb.service.status:") + " " +
                 (detectorStatus.isRunning ? String(localized: "usb.service.running")
                                            : String(localized: "usb.service.paused")))

            Divider()

            if !detectorStatus.isRunning {
                Button("usb.service.start") {
                    USBDetector.shared.startDetection()
                }
            } else {
                Button("usb.service.pause") {
                    USBDetector.shared.stopDetection()
                }
            }

            Divider()

            Menu {
                Picker("usb.service.delay", selection: $storage.detectionDelay) {
                    ForEach(possibleDetectionDelays, id: \.self) { delay in
                        Text("\(delay) second" + (delay == 1 ? "" : String(localized: "plural.ext"))).tag(delay)
                    }
                }

                Toggle(isOn: $storage.connectionSound) {
                    Text("usb.service.makeSound")
                }

                Toggle(isOn: $storage.ephemeralNotifs) {
                    Text("usb.service.ephemeral")
                }

                Toggle(isOn: $autostart.status) {
                    Text("usb.service.autostart")
                }
            }
            label: {
                Label("settings", systemImage: "gearshape")
            }

            Button("app.quit") {
                exit(0)
            }
        }
    }

    func restartDetection() {
        USBDetector.shared.stopDetection()
        USBDetector.shared.startDetection()
    }
}

#Preview {
    MenuBarView()
}
