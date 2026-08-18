// Copyright © 2026 Polar Electro Oy. All rights reserved.

import Foundation

/// Represents a log file fetched from a Polar device.
///
/// - `path`: the file path on the device (e.g. "/ERRORLOG.BPB")
/// - `data`: the raw file contents
public struct PolarDeviceLog {
    /// The file path on the device (e.g. "/ERRORLOG.BPB")
    public let path: String
    /// The raw file contents
    public let data: Data

    public init(path: String, data: Data) {
        self.path = path
        self.data = data
    }
}

