//
//  Storage.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation
import SwiftUI

struct Storage {
    static var shared = Storage()

    @AppStorage("connectionSound") var connectionSound = false
    @AppStorage("ephemeralNotifs") var ephemeralNotifs = false
}

extension Storage {
    final class Observable: ObservableObject {

        var connectionSound: Bool {
            get { Storage.shared.connectionSound }
            set {
                Storage.shared.connectionSound = newValue
                objectWillChange.send()
            }
        }
        var ephemeralNotifs: Bool {
            get { Storage.shared.ephemeralNotifs }
            set {
                Storage.shared.ephemeralNotifs = newValue
                objectWillChange.send()
            }
        }
    }
}
