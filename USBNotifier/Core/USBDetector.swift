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

    fileprivate let observable = Observable()

    private var isRunning = false

    private func unpackDevicesFromIterator(iterator: io_iterator_t) -> [USBDevice] {
        var devices = [USBDevice]()

        var device = IOIteratorNext(iterator)
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
            device = IOIteratorNext(iterator)
        }

        return devices
    }

    private func sendNotifications(for device: USBDevice,
                                   status: USBConnectionStatus,
                                   sound: Bool = false) {
        let notificationContent = UNMutableNotificationContent()
        switch status {
        case .connected:
            notificationContent.title = String(localized: "usb.connected")
        case .disconnected:
            notificationContent.title = String(localized: "usb.disconnected")
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

    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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

    private var newDevices: [USBDevice] = []
    private var newDevicesTimer: Timer?
    private var newDevicesIterator: io_iterator_t = IO_OBJECT_NULL

    private var removedDevices: [USBDevice] = []
    private var removedDevicesTimer: Timer?
    private var removedDevicesIterator: io_iterator_t = IO_OBJECT_NULL

    private func processNewDevices(iterator: io_iterator_t) {
        newDevicesTimer?.invalidate()

        self.newDevices.append(contentsOf: unpackDevicesFromIterator(iterator: iterator))

        newDevicesTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.newDevices.count > 1 {
                self.sendNotifications(for: self.newDevices,
                                  status: .connected,
                                  sound: Storage.shared.connectionSound)
            } else if self.newDevices.count == 1 {
                self.sendNotifications(for: self.newDevices[0],
                                  status: .connected,
                                  sound: Storage.shared.connectionSound)
            }

            self.newDevices.removeAll()
        }
    }

    private func processRemovedDevices(iterator: io_iterator_t) {
        removedDevicesTimer?.invalidate()

        self.removedDevices.append(contentsOf: unpackDevicesFromIterator(iterator: iterator))

        removedDevicesTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.removedDevices.count > 1 {
                self.sendNotifications(for: self.removedDevices,
                                  status: .disconnected,
                                  sound: Storage.shared.connectionSound)
            } else if self.removedDevices.count == 1 {
                self.sendNotifications(for: self.removedDevices[0],
                                  status: .disconnected,
                                  sound: Storage.shared.connectionSound)
            }

            self.removedDevices.removeAll()
        }
    }

    private var notificationPort: IONotificationPortRef?

    private func startDetection() {
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)

        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.defaultMode)

        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)

        let newDevicesCallbackClosure: IOServiceMatchingCallback = { context, iterator in
            let detector = Unmanaged<USBDetector>.fromOpaque(context!).takeUnretainedValue()
            detector.processNewDevices(iterator: iterator)
        }

        let resultAddedDevices = IOServiceAddMatchingNotification(notificationPort,
                                    kIOMatchedNotification,
                                    matchingDict,
                                    newDevicesCallbackClosure,
                                    Unmanaged.passUnretained(self).toOpaque(),
                                    &newDevicesIterator)

        let removedDevicesCallbackClosure: IOServiceMatchingCallback = { context, iterator in
            let detector = Unmanaged<USBDetector>.fromOpaque(context!).takeUnretainedValue()
            detector.processRemovedDevices(iterator: iterator)
        }

        let resultRemovedDevices = IOServiceAddMatchingNotification(notificationPort,
                                    kIOTerminatedNotification,
                                    matchingDict,
                                    removedDevicesCallbackClosure,
                                    Unmanaged.passUnretained(self).toOpaque(),
                                    &removedDevicesIterator)

        if resultAddedDevices == kIOReturnSuccess && resultRemovedDevices == kIOReturnSuccess {
            // Clear the initial devices.
            _ = unpackDevicesFromIterator(iterator: newDevicesIterator)
            _ = unpackDevicesFromIterator(iterator: removedDevicesIterator)
            self.isRunning = true
        } else {
            stopDetection()
        }
    }

    private func stopDetection() {
        if let notificationPort = notificationPort {
            let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.defaultMode)
            IONotificationPortDestroy(notificationPort)
        }

        notificationPort = nil

        if newDevicesIterator != 0 {
            _ = unpackDevicesFromIterator(iterator: newDevicesIterator)
            IOObjectRelease(newDevicesIterator)
            newDevicesIterator = IO_OBJECT_NULL
        }

        if removedDevicesIterator != 0 {
            _ = unpackDevicesFromIterator(iterator: removedDevicesIterator)
            IOObjectRelease(removedDevicesIterator)
            removedDevicesIterator = IO_OBJECT_NULL
        }

        self.isRunning = false
    }

    deinit {
        stopDetection()
    }
}

extension USBDetector {
    final class Observable: ObservableObject {
        var status: Bool {
            get {
                return USBDetector.shared.isRunning
            }
            set {
                if newValue {
                    USBDetector.shared.startDetection()
                } else {
                    USBDetector.shared.stopDetection()
                }
                objectWillChange.send()
            }
        }
    }
}
