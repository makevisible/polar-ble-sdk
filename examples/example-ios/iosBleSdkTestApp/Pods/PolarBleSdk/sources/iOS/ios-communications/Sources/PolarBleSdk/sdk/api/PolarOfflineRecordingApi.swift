/// Copyright © 2023 Polar Electro Oy. All rights reserved.

import Foundation
import RxSwift

/// Offline recording API.
///
/// Offline recording makes it possible to record `PolarBleApi.PolarDeviceDataType` data to device memory.
/// With Offline recording the Polar device and phone don't need to be connected all the time, as offline recording continues in Polar device even the BLE disconnects.
///
///  Offline records saved into the device can be encrypted. The  `PolarRecordingSecret` is provided for
///  `startOfflineRecording` and `setOfflineRecordingTrigger` when encryption is wanted.
///  The `PolarRecordingSecret` with same key must be provided in `getOfflineRecord` to correctly
///  decrypt the data in the device.
///
/// Requires features `PolarBleSdkFeature.feature_polar_offline_recording`
///
/// Note, offline recording is supported in Polar Verity Sense device (starting from firmware version 2.1.0)
///
public protocol PolarOfflineRecordingApi {
    ///  Get the data types available in this device for offline recording
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    /// - Returns: Single stream
    ///   - success:  set of available offline recording data types in this device
    ///   - onError: see `PolarErrors` for possible errors invoked
    func getAvailableOfflineRecordingDataTypes(_ identifier: String) -> Single<Set<PolarDeviceDataType>>
    
    ///  Request the offline recording settings available in current operation mode. This request shall be used before the offline recording is started
    ///  to decide currently available settings. The available settings depend on the state of the device.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    ///   - feature: selected feature from`PolarDeviceDataType`
    /// - Returns: Single stream
    ///   - success: once after settings received from device
    ///   - onError: see `PolarErrors` for possible errors invoked
    func requestOfflineRecordingSettings(_ identifier: String, feature: PolarDeviceDataType) -> Single<PolarSensorSetting>
    
    ///  Request all the settings available in the device. The request returns the all capabilities of the requested streaming feature not limited by the current operation mode.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    ///   - feature: selected feature from`PolarDeviceDataType`
    /// - Returns: Single stream
    ///   - success: once after settings received from device
    ///   - onError: see `PolarErrors` for possible errors invoked
    func requestFullOfflineRecordingSettings(_ identifier: String, feature: PolarDeviceDataType) -> Single<PolarSensorSetting>
    
    /// Get status of offline recordings.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    /// - Returns: Single stream
    ///   - success: the dictionary indicating the offline recording status, if the value in dictionary is true the offline recording is currently recording
    ///   - error: see `PolarErrors` for possible errors invoked
    func getOfflineRecordingStatus(_ identifier: String)-> Single<[PolarDeviceDataType:Bool]>
    
    /// List offline recordings stored in the device.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    /// - Returns: Completable
    ///   - next :  the found offline recording entry
    ///   - completed: the listing completed
    ///   - error: see `PolarErrors` for possible errors invoked
    func listOfflineRecordings(_ identifier: String) -> Observable<PolarOfflineRecordingEntry>
    
    /// Fetch recording from the  device.
    ///
    /// Note, the fetching of the recording may take several seconds if the recording is big.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    ///   - entry:  The offline recording to be fetched
    ///   - secret: If the secret is provided in `startOfflineRecording` or `setOfflineRecordingTrigger` then the same secret must be provided when fetching the offline record
    /// - Returns: Single
    ///   - success :  the offline recording data
    ///   - error: fetch recording request failed. see `PolarErrors` for possible errors invoked
    func getOfflineRecord(_ identifier: String, entry: PolarOfflineRecordingEntry, secret: PolarRecordingSecret?) -> Single< PolarOfflineRecordingData>
    
    /// Removes offline recording from the device
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    ///   - entry: entry to be removed
    /// - Returns: Completable
    ///   - completed :  offline record is removed
    ///   - error:  offline record removal failed, see `PolarErrors` for possible errors invoked
    func removeOfflineRecord(_ identifier: String, entry: PolarOfflineRecordingEntry) -> Completable
    
    /// Start offline recording.
    ///
    /// - Parameters:
    ///   - identifier: polar device id
    ///   - feature: the feature to be started
    ///   - settings: optional settings used for offline recording. `PolarDeviceDataType.hr` and `PolarDeviceDataType.ppi` do not require settings
    /// - Returns: Completable
    ///   - completed :  offline recording is started successfully
    ///   - error: see `PolarErrors` for possible errors invoked
    func startOfflineRecording(_ identifier: String, feature: PolarDeviceDataType, settings: PolarSensorSetting?) -> Completable
    
    /// Request to stop offline recording.
    ///
    /// - Parameters:
    ///   - identifier:  polar device id
    ///   - feature: the feature to be stopped
    /// - Returns: Completable
    ///   - completed :  offline recording is stop successfully
    ///   - error: offline recording stop failed. see `PolarErrors` for possible errors invoked
    func stopOfflineRecording(_ identifier: String, feature: PolarDeviceDataType) -> Completable
}
