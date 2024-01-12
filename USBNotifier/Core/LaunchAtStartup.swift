//
//  LaunchAtStartup.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation
import ServiceManagement

struct LaunchAtStartup {
    static public var shared = LaunchAtStartup()

    fileprivate let observable = Observable()

    public var status: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue {
                setItemLaunchAtLogin()
            } else {
                unsetItemLaunchAtLogin()
            }
        }
    }

    private func setItemLaunchAtLogin() {
        // Use SMAppService.register because Apple is Apple.
        do {
            if status == true {
                try? SMAppService.mainApp.unregister()
            }
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Failed to register \(error.localizedDescription).")
        }
    }

    private func unsetItemLaunchAtLogin() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            NSLog("Failed to register \(error.localizedDescription).")
        }
    }
}

extension LaunchAtStartup {
	final class Observable: ObservableObject {
		var status: Bool {
            get { LaunchAtStartup.shared.status }
			set {
                LaunchAtStartup.shared.status = newValue
                objectWillChange.send()
			}
		}
	}
}
