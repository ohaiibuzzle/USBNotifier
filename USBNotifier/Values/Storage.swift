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
}
