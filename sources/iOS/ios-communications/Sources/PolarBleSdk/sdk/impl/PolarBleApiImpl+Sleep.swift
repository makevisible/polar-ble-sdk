/// Copyright © 2019 Polar Electro Oy. All rights reserved.

import Foundation
import CoreBluetooth
import RxSwift

#if os(iOS)
import UIKit
#endif

/// Implementation of PolarSleepApi
/// Depends on PolarRestServiceApi

extension PolarBleApiImpl: PolarSleepApi {
    
    func stopSleepRecording(identifier: String) -> RxSwift.Completable {
        return self.putNotification(identifier: identifier,
                                    notification: "{}",
                                    path: "/REST/SLEEP.API?cmd=post&endpoint=stop_sleep_recording")
    }
    
    internal struct SleepRecordingState: Decodable {
        let enabled: Int?
        enum CodingKeys: String, CodingKey {
            case enabled
        }
        var isEnabled: Bool {
            return  enabled ?? 0 == 1
        }
    }
    
    internal struct SleepRecordingStateWrapper: Decodable {
        private let sleep_recording_state: SleepRecordingState
        enum CodingKeys: String, CodingKey {
            case sleep_recording_state
        }
        var sleepRecordingState: SleepRecordingState {
            return sleep_recording_state
        }
    }
    

    func getSleepRecordingState(identifier: String) -> Single<Bool> {
        BleLogger.trace("getSleepRecordingState: called for identifier: \(identifier)")
        let observeRecordingState = observeSleepRecordingState(identifier: identifier)
            .do(
                onNext: { value in
                    BleLogger.trace("getSleepRecordingState: Received value: \(value)")
                },
                onError: { error in
                    BleLogger.trace("getSleepRecordingState: error: \(error)")
                },
                onSubscribe: {
                    BleLogger.trace("getSleepRecordingState: Subscribed to observeSleepRecordingState")
                },
                onDispose: {
                    BleLogger.trace("getSleepRecordingState: onDispose")
                }
            )
            .filter { !$0.isEmpty }
            .take(1)
            .map { $0.last! }
            .asSingle()
        return observeRecordingState
    }
        
    func observeSleepRecordingState(identifier: String) -> Observable<[Bool]> {
        BleLogger.trace("observeSleepRecordingState: called for identifier: \(identifier)")
        let receiveSleepRecordingStates: Observable<[SleepRecordingStateWrapper]> =
            self.receiveRestApiEvents(identifier: identifier)
        let receiveSleepRecordingEnabled = receiveSleepRecordingStates
            .do(
                onNext: { value in
                    BleLogger.trace("observeSleepRecordingState: Received event payloads: \(value)")
                },
                onError: { error in
                    BleLogger.trace("observeSleepRecordingState: Error: \(error)")
                },
                onSubscribe: {
                    BleLogger.trace("observeSleepRecordingState: Subscribed to receiveRestApiEvents")
                },
                onDispose: {
                    BleLogger.trace("observeSleepRecordingState: onDispose")
                }
            )
            .compactMap {
                let boolArray = $0.compactMap { $0.sleepRecordingState.isEnabled }
                BleLogger.trace("observeSleepRecordingState: Mapped to Boolean array: \(boolArray)")
                return boolArray
            }
        let subscribe = self.putNotification(identifier: identifier, notification: "{}",
                             path: "/REST/SLEEP.API?cmd=subscribe&event=sleep_recording_state&details=[enabled]")
        return subscribe
            .do(onCompleted: {
                BleLogger.trace("observeSleepRecordingState: Subscription notification sent")
            })
            .andThen(receiveSleepRecordingEnabled)
    }
    
    func getSleepData(identifier: String, fromDate: Date, toDate: Date) -> Single<[PolarSleepData.PolarSleepAnalysisResult]> {
        
        if (fromDate > toDate) {
            return Single.error(PolarErrors.invalidArgument(description: "toDate cannot be smaller than fromDate."))
        }
        
        do {
            let session = try self.sessionFtpClientReady(identifier)
            guard let client = session.fetchGattClient(BlePsFtpClient.PSFTP_SERVICE) as? BlePsFtpClient else {
                return Single.error(PolarErrors.serviceNotFound)
            }
            
            var sleepDataList = [PolarSleepData.PolarSleepAnalysisResult]()
            let calendar = Calendar.current
            var datesList = [Date]()
            var currentDate = fromDate
            
            if (fromDate == toDate) {
                datesList.append(fromDate)
            } else {
                while currentDate <= toDate {
                    datesList.append(currentDate)
                    if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                        currentDate = nextDate
                    } else {
                        break
                    }
                }
            }
            return Observable.from(datesList)
                .flatMap { date -> Single<(PolarSleepData.PolarSleepAnalysisResult)> in
                    return PolarSleepUtils.readSleepFromDayDirectory(client: client, date: date)
                        .map { sleepData -> (PolarSleepData.PolarSleepAnalysisResult) in
                            return sleepData
                        }
                }
                .toArray()
                .map { sleepAnalysisResult -> [PolarSleepData.PolarSleepAnalysisResult] in
                    // Create an unwrapped copy of sleepDataList to allow removal of nil PolarSleepAnalysisResults from the list.
                    var sleepDataList = [PolarSleepData.PolarSleepAnalysisResult]()
                    sleepDataList.append(contentsOf: sleepAnalysisResult)
                    for sleepData in sleepDataList {
                        if (sleepData.sleepStartTime == nil) {
                            if let index = sleepDataList.firstIndex(where: { $0.lastModified == sleepData.lastModified }) {
                                sleepDataList.remove(at: index)
                            }
                        }
                    }
                    return sleepDataList
                }
        } catch {
            return Single.error(error)
        }
    }
}
