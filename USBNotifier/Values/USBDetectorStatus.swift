//
//  USBDetectorStatus.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation

class USBDetectorStatus: ObservableObject {
    static var shared = USBDetectorStatus()

    @Published var isRunning: Bool = false
}
