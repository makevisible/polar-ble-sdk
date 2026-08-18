// Copyright © 2026 Polar Electro Oy. All rights reserved.

import Foundation

/// Polar logging API.
///
/// Provides access to diagnostic and trace log files stored on a Polar device,
/// as well as the device sensor data log configuration.
///
/// Requires feature `PolarBleSdkFeature.feature_polar_file_transfer`.
public protocol PolarLoggingApi {

    /// Export all available diagnostic and trace log files from the device.
    ///
    /// The following files are attempted in order. Files that do not exist on the
    /// device are silently omitted from the result:
    ///
    /// - `/ERRORLOG.BPB`   – Primary error log
    /// - `/ERRORLO2.BPB`   – Secondary error log
    /// - `/SYSLOG.TXT`     – System log
    /// - `/TRC1.BIN`, `/TRC2.BIN`, … – Device telemetry data.
    ///   Files are fetched sequentially starting from index 1 until a file is not found.
    /// - `/DBGTRC1.BIN`, `/DBGTRC2.BIN`, … – Device debug trace data.
    ///   Files are fetched sequentially starting from index 1 until a file is not found.
    ///
    /// - Requires SDK feature(s): `PolarBleSdkFeature.feature_polar_file_transfer`
    /// - Parameter identifier: Polar device ID or BT address
    /// - Returns: List of `PolarDeviceLog` entries for all log files that exist on the device.
    /// - Throws: See `PolarErrors` for possible errors invoked.
    ///
    func exportDeviceLogs(_ identifier: String) async throws -> [PolarDeviceLog]

    /// Get log configuration from a device (SDLOGS.BPB)
    ///
    /// - Requires SDK feature(s): `PolarBleSdkFeature.feature_polar_device_control`
    /// - Parameter identifier: Polar device ID or BT address
    /// - Returns: `LogConfig` describing the current SD log configuration on the device.
    /// - Throws: See `PolarErrors` for possible errors invoked.
    ///
    func getLogConfig(_ identifier: String) async throws -> LogConfig

    /// Set log configuration to a device (SDLOGS.BPB)
    ///
    /// - Requires SDK feature(s): `PolarBleSdkFeature.feature_polar_device_control`
    /// - Parameter identifier: Polar device ID or BT address
    /// - Parameter logConfig: log configuration to write to the device.
    /// - Throws: See `PolarErrors` for possible errors invoked.
    ///
    func setLogConfig(_ identifier: String, logConfig: LogConfig) async throws
}
