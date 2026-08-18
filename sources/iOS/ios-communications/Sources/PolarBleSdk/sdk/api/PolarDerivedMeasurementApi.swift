// Copyright © 2026 Polar Electro Oy. All rights reserved.

import Foundation

/// Derived measurement API.
///
/// Derived measurements compute statistical summaries (e.g. min, max, std) over a
/// configurable time window of raw sensor data and store one result per window.
public protocol PolarDerivedMeasurementApi {

    /// Query which Derived Measurement Settings Group IDs are supported for the given source type.
    ///
    /// Call this before `requestDerivedMeasurementSettingsGroup` to discover which group IDs
    /// the device advertises for a source type (e.g. ACC).
    ///
    /// - Parameters:
    ///   - identifier: Polar device id found printed on the sensor/device or bt address
    ///   - sourceType: the source measurement type to query (typically `.acc`)
    /// - Returns: set of Derived Measurement Settings Group IDs advertised by the device for this source type
    /// - Throws: `PolarErrors` for possible errors invoked
    func requestDerivedMeasurementGroupIds(
        _ identifier: String,
        sourceType: PolarDeviceDataType
    ) async throws -> Set<Int>

    /// Request the full contents of one Derived Measurement Settings Group from the device.
    ///
    /// Use this before starting a derived recording to discover which source types, sample rates,
    /// time windows, and computation methods are supported by a group.
    ///
    /// Typical flow:
    /// 1. Call `requestDerivedMeasurementGroupIds` for the source type to get available group IDs.
    /// 2. Call this function for each group ID of interest.
    /// 3. Present `supportedMethods` to the user for selection.
    /// 4. Build `PolarDerivedMeasurementSettings` from the user's choices.
    /// 5. Call `startDerivedOfflineRecording`.
    ///
    /// - Parameters:
    ///   - identifier: Polar device id found printed on the sensor/device or bt address
    ///   - groupId: the Derived Measurement Settings Group ID to query
    /// - Returns: `PolarDerivedMeasurementSettingsGroup` describing the available options for this group
    /// - Throws: `PolarErrors` for possible errors invoked
    func requestDerivedMeasurementSettingsGroup(
        _ identifier: String,
        groupId: Int
    ) async throws -> PolarDerivedMeasurementSettingsGroup

    /// Start a derived offline recording on the device.
    ///
    /// The device computes the selected derived methods over each
    /// `PolarDerivedMeasurementSettings.timeWindowMs` time window of source data and stores
    /// one derived sample per window. Fetch results with `getOfflineRecord`.
    ///
    /// - Parameters:
    ///   - identifier: Polar device id found printed on the sensor/device or bt address
    ///   - settings: the derived measurement settings including the chosen methods
    ///   - secret: optional encryption secret; if provided, the recording is encrypted on device
    /// - Throws: `PolarErrors` for possible errors invoked
    func startDerivedOfflineRecording(
        _ identifier: String,
        settings: PolarDerivedMeasurementSettings,
        secret: PolarRecordingSecret?
    ) async throws

    /// Stop the active derived offline recording on the device.
    ///
    /// - Parameters:
    ///   - identifier: Polar device id found printed on the sensor/device or bt address
    /// - Throws: `PolarErrors` for possible errors invoked
    func stopDerivedOfflineRecording(_ identifier: String) async throws
}
