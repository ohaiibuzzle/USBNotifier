//
//  USBControl.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation

struct USBControl {
    static var shared = USBControl()

    func ejectEverything() {
        let script = """
        tell application "Finder"
            eject (every disk whose ejectable is true)
        end tell
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
}
