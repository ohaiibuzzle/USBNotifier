//
//  USBDetector.swift
//  USBNotifier
//
//  Created by Venti on 12/01/2024.
//

import Foundation
import IOKit.usb
import UserNotifications

struct USBDevice: Identifiable {
    var id: String {
        return "\(vendorID)-\(productID)"
    }
    var vendorID: Int
    var productID: Int
    var manufacturer: String
    var product: String
}

enum USBConnectionStatus {
    case connected
    case disconnected
}

class USBDetector {
    static var shared = USBDetector()

    private var detectionTask: Task<Void, Never>?

    private func fetchUSBDevices() -> [USBDevice] {
        var devices = [USBDevice]()
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        let iterator = UnsafeMutablePointer<io_iterator_t>.allocate(capacity: 1)
        let kernResult = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, iterator)
        let devicePtr = iterator.pointee
        if kernResult != KERN_SUCCESS {
            print("Error: \(kernResult)")
            return devices
        }
        if devicePtr == 0 {
            // print("No USB devices found")
            return devices
        }
        var device = IOIteratorNext(devicePtr)
        while device != 0 {
            // Initialize variables for the object properties
            var vendorID: Int = 0
            var productID: Int = 0
            var manufacturer: String = ""
            var product: String = ""

            // Get the USB device's vendor ID
            if let vendorIDCF = IORegistryEntryCreateCFProperty(device,
                                                                kUSBVendorID as CFString,
                                                                kCFAllocatorDefault, 0) {
                vendorID = (vendorIDCF.takeRetainedValue() as? NSNumber)?.intValue ?? 0
            }

            // Get the USB device's product ID
            if let productIDCF = IORegistryEntryCreateCFProperty(device,
                                                                 kUSBProductID as CFString,
                                                                 kCFAllocatorDefault, 0) {
                productID = (productIDCF.takeRetainedValue() as? NSNumber)?.intValue ?? 0
            }

            // Get the USB device's manufacturer name
            if let manufacturerCF = IORegistryEntryCreateCFProperty(device,
                                                                    kUSBVendorString as CFString,
                                                                    kCFAllocatorDefault, 0) {
                manufacturer = (manufacturerCF.takeRetainedValue() as? String) ?? ""
            }

            // Get the USB device's product name
            if let productCF = IORegistryEntryCreateCFProperty(device,
                                                               kUSBProductString as CFString,
                                                               kCFAllocatorDefault, 0) {
                product = (productCF.takeRetainedValue() as? String) ?? ""
            }

            // Create a new USB device object and add it to the list of devices
            let newDevice = USBDevice(vendorID: vendorID,
                                      productID: productID,
                                      manufacturer: manufacturer,
                                      product: product)
            devices.append(newDevice)

            // Release the device object
            IOObjectRelease(device)
            device = IOIteratorNext(devicePtr)
        }
        // Release the iterator
        IOObjectRelease(devicePtr)
        return devices
    }

    private func sendNotifications(for device: USBDevice,
                                   status: USBConnectionStatus,
                                   sound: Bool = false) {
        let notificationContent = UNMutableNotificationContent()
        switch status {
        case .connected:
            notificationContent.title = String("usb.connected")
        case .disconnected:
            notificationContent.title = String("usb.disconnected")
        }
        notificationContent.body = "\(device.manufacturer) \(device.product)"

        if sound {
            notificationContent.sound = UNNotificationSound.default
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: notificationContent,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    private func sendNotifications(for devices: [USBDevice],
                                   status: USBConnectionStatus,
                                   sound: Bool = false) {
        // Count the number of devices connected/disconnected
        var deviceCount = 0
        var deviceString = ""
        for device in devices {
            deviceCount += 1
            deviceString += "\(device.manufacturer) \(device.product)"
            if deviceCount < devices.count {
                deviceString += "\n"
            }
        }

        let notificationContent = UNMutableNotificationContent()
        switch status {
        case .connected:
            notificationContent.title = String(localized: "\(deviceCount) usb.devices.connected")
        case .disconnected:
            notificationContent.title = String(localized: "\(deviceCount) usb.devices.disconnected")
        }
        notificationContent.body = deviceString

        if sound {
            notificationContent.sound = UNNotificationSound.default
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: notificationContent,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    private func detectionLoop() {
        var devices = fetchUSBDevices()
        while true {
            let newDevices = fetchUSBDevices()

            var connectedDevices = [USBDevice]()
            var disconnectedDevices = [USBDevice]()

            for device in newDevices where !devices.contains(where: { $0.id == device.id }) {
                connectedDevices.append(device)
            }

            for device in devices where !newDevices.contains(where: { $0.id == device.id }) {
                disconnectedDevices.append(device)
            }

            // Prevent mass notifications spam
            if connectedDevices.count > 1 {
                sendNotifications(for: connectedDevices,
                                  status: .connected,
                                  sound: Storage.shared.connectionSound)
            } else if connectedDevices.count == 1 {
                sendNotifications(for: connectedDevices[0],
                                  status: .connected,
                                  sound: Storage.shared.connectionSound)
            }

            if disconnectedDevices.count > 1 {
                sendNotifications(for: disconnectedDevices,
                                  status: .disconnected,
                                  sound: Storage.shared.connectionSound)
            } else if disconnectedDevices.count == 1 {
                sendNotifications(for: disconnectedDevices[0],
                                  status: .disconnected,
                                  sound: Storage.shared.connectionSound)
            }

            devices = newDevices
            sleep(UInt32(Storage.shared.detectionDelay))
        }
    }

    func startDetection() {
        if detectionTask == nil {
            detectionTask = Task.detached(priority: .background) {
                self.detectionLoop()
            }
        }
        USBDetectorStatus.shared.isRunning = true
    }

    func stopDetection() {
        if detectionTask != nil {
            self.detectionTask?.cancel()
        }
        USBDetectorStatus.shared.isRunning = false
    }
}
