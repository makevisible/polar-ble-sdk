/// Copyright © 2023 Polar Electro Oy. All rights reserved.

import Foundation
import PolarBleSdk

let nullPolarDeviceInfo = (deviceId: "no device", address: UUID(), rssi: 0, name: "no device", connectable: false, false)

enum DeviceConnectionState {
    case noDevice(PolarDeviceInfo)
    case connecting(PolarDeviceInfo)
    case connected(PolarDeviceInfo)
    case disconnected(PolarDeviceInfo)
//    case disconnecting(PolarDeviceInfo)
    
    func get() -> PolarDeviceInfo {
        switch self {
        case .noDevice(let deviceInfo), .connected(let deviceInfo), .disconnected(let deviceInfo), .connecting(let deviceInfo):
            return deviceInfo
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
