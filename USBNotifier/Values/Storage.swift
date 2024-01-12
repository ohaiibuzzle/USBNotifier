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

    @AppStorage("detectionDelay") var detectionDelay = 1
    @AppStorage("connectionSound") var connectionSound = false
    @AppStorage("ephemeralNotifs") var ephemeralNotifs = false
}

extension Storage {
    final class Observable: ObservableObject {
        var detectionDelay: Int {
            get { Storage.shared.detectionDelay }
            set { Storage.shared.detectionDelay = newValue }
        }
        var connectionSound: Bool {
            get { Storage.shared.connectionSound }
            set { Storage.shared.connectionSound = newValue }
        }
        var ephemeralNotifs: Bool {
            get { Storage.shared.ephemeralNotifs }
            set { Storage.shared.ephemeralNotifs = newValue }
        }
    }
}
