//
//  Dialogs.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation
import AppKit

struct Dialogs {
    func showDialog(with title: String, _ content: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = content
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "dialog.ok"))
        alert.runModal()
    }
}
