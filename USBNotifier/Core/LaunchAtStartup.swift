//
//  LaunchAtStartup.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation
import ServiceManagement

struct LaunchAtStartup {
    fileprivate static let observable = Observable()

    public static var status: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            observable.objectWillChange.send()
            if newValue {
                setItemLaunchAtLogin()
            } else {
                unsetItemLaunchAtLogin()
            }
        }
    }

    private static func setItemLaunchAtLogin() {
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

    private static func unsetItemLaunchAtLogin() {
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
			get { LaunchAtStartup.status }
			set {
				LaunchAtStartup.status = newValue
			}
		}
	}
}
