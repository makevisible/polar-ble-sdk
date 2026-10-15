//
//  Copyright © 2024 Polar. All rights reserved.
//

import Foundation

public class PolarSleepData {

    public enum SleepWakeState: String, Codable {
        case UNKNOWN = "UNKNOWN"
        case WAKE = "WAKE"
        case REM = "REM"
        case NONREM12 = "NONREM12"
        case NONREM3 = "NONREM3"

        static func getByValue(value: Int) -> SleepWakeState {

            switch value {
            case 0: return .UNKNOWN
            case -2: return .WAKE
            case -3: return .REM
            case -5: return .NONREM12
            case -6: return .NONREM3
            default: return .UNKNOWN
            }
        }
    }

    public enum SleepRating: Int, Codable {
        case SLEPT_UNDEFINED = -1
        case SLEPT_POORLY = 0
        case SLEPT_SOMEWHAT_POORLY = 1
        case SLEPT_NEITHER_POORLY_NOR_WELL = 2
        case SLEPT_SOMEWHAT_WELL = 3
        case SLEPT_WELL = 4

        static func getByValue(value: Int) -> SleepRating {
            guard let status = SleepRating(rawValue: value) else {
                BleLogger.error("Invalid SleepRating value: \(value)")
                return SLEPT_UNDEFINED
            }
            return status
        }
    }

    public struct PolarSleepAnalysisResult: Codable {
        public let sleepStartTime: Date!
        public let sleepEndTime: Date!
        public let lastModified: Date!
        public let sleepGoalMinutes: UInt32!
        public let sleepWakePhases: [SleepWakePhase]!
        public let snoozeTime: [Date]?
        public let alarmTime: Date?
        public let sleepStartOffsetSeconds: Int32!
        public let sleepEndOffsetSeconds: Int32!
        public let userSleepRating: SleepRating?
        public let deviceId: String?
        public let batteryRanOut: Bool?
        public let sleepCycles: [SleepCycle]!
        public let sleepResultDate: DateComponents?
        public let originalSleepRange: OriginalSleepRange?
        public var sleepSkinTemperatureResult: SleepSkinTemperatureResult?

        public init(sleepStartTime: Date!,
                    sleepEndTime: Date!,
                    lastModified: Date!,
                    sleepGoalMinutes: UInt32!,
                    sleepWakePhases: [SleepWakePhase]!,
                    snoozeTime: [Date]?,
                    alarmTime: Date?,
                    sleepStartOffsetSeconds: Int32!,
                    sleepEndOffsetSeconds: Int32!,
                    userSleepRating: SleepRating?,
                    deviceId: String?,
                    batteryRanOut: Bool?,
                    sleepCycles: [SleepCycle]!,
                    sleepResultDate: DateComponents?,
                    originalSleepRange: OriginalSleepRange?,
                    sleepSkinTemperatureResult: SleepSkinTemperatureResult? = nil) {
            self.sleepStartTime = sleepStartTime
            self.sleepEndTime = sleepEndTime
            self.lastModified = lastModified
            self.sleepGoalMinutes = sleepGoalMinutes
            self.sleepWakePhases = sleepWakePhases
            self.snoozeTime = snoozeTime
            self.alarmTime = alarmTime
            self.sleepStartOffsetSeconds = sleepStartOffsetSeconds
            self.sleepEndOffsetSeconds = sleepEndOffsetSeconds
            self.userSleepRating = userSleepRating
            self.deviceId = deviceId
            self.batteryRanOut = batteryRanOut
            self.sleepCycles = sleepCycles
            self.sleepResultDate = sleepResultDate
            self.originalSleepRange = originalSleepRange
            self.sleepSkinTemperatureResult = sleepSkinTemperatureResult
        }
    }

    public struct SleepWakePhase: Codable {
        public var secondsFromSleepStart: UInt32!
        public var state: SleepWakeState!

        public init(secondsFromSleepStart: UInt32! = nil, state: SleepWakeState! = nil) {
            self.secondsFromSleepStart = secondsFromSleepStart
            self.state = state
        }
    }

    public struct SleepCycle: Codable {
        public let secondsFromSleepStart: UInt32!
        public let sleepDepthStart: Float!

        public init(secondsFromSleepStart: UInt32!, sleepDepthStart: Float!) {
            self.secondsFromSleepStart = secondsFromSleepStart
            self.sleepDepthStart = sleepDepthStart
        }
    }

    public struct OriginalSleepRange: Codable {
        public let startTime: Date?
        public let endTime: Date?
        
    }

    /// Polar sleep time skin temperature data.
    ///
    ///     - sleepResultDate (year, month, day) of the sleep skin temperature data
    ///     - deviationFromBaseLine: Deviation to users sleep body temperature history. Unit=celsius. Value is -1000.0 when not calculated.
    ///     - sleepTimeSkinTemperatureCelsius: unit=celsius
    public struct SleepSkinTemperatureResult: Codable {
        public let sleepResultDate: Date?
        public let sleepSkinTemperatureCelsius: Float
        public let deviationFromBaseLine: Float
    }

    static func fromPbSleepwakePhasesListProto(pbSleepwakePhasesList: [Data_PbSleepWakePhase]) -> [PolarSleepData.SleepWakePhase] {
        
        var sleepwakePhasesList = [SleepWakePhase]()
        
        for pbSleepWakePhase in pbSleepwakePhasesList {
            let sleepWakePhase = PolarSleepData.SleepWakePhase(secondsFromSleepStart: pbSleepWakePhase.secondsFromSleepStart, state: PolarSleepData.SleepWakeState.getByValue(value: pbSleepWakePhase.sleepwakeState.rawValue))
            sleepwakePhasesList.append(sleepWakePhase)
        }
        return sleepwakePhasesList
    }

    static func fromPbSleepCyclesList(pbSleepCyclesList: [Data_PbSleepCycle]) -> [SleepCycle] {

        var sleepCyclesList = [SleepCycle]()

        for pbSleepCycle in pbSleepCyclesList {
            let sleepCycle = SleepCycle(secondsFromSleepStart: pbSleepCycle.secondsFromSleepStart, sleepDepthStart: pbSleepCycle.sleepDepthStart)
            sleepCyclesList.append(sleepCycle)
        }

        return sleepCyclesList
    }

    static func fromPbOriginalSleepRange(pbOriginalSleepRange: PbLocalDateTimeRange) throws -> OriginalSleepRange {

        let startTime = pbOriginalSleepRange.hasStartTime ? try PolarTimeUtils.pbLocalDateTimeToDate(pbLocalDateTime: pbOriginalSleepRange.startTime) : nil
        let endTime = pbOriginalSleepRange.hasEndTime ?  try PolarTimeUtils.pbLocalDateTimeToDate(pbLocalDateTime: pbOriginalSleepRange.endTime) : nil

        return OriginalSleepRange(
            startTime: startTime,
            endTime: endTime)
    }

    static func fromPbSleepTemperatureResult(pbSleepTemperatureResult: Data_PbSleepSkinTemperatureResult) throws -> SleepSkinTemperatureResult {

        let sleepResultDate = pbSleepTemperatureResult.hasSleepDate ? try PolarTimeUtils.pbDateProto3ToDate(pbDate: pbSleepTemperatureResult.sleepDate) : nil
        let sleepSkinTemperatureCelsius = pbSleepTemperatureResult.sleepSkinTemperatureCelsius
        let deviationFromBaseLine = pbSleepTemperatureResult.deviationFromBaselineCelsius
        return SleepSkinTemperatureResult(sleepResultDate: sleepResultDate, sleepSkinTemperatureCelsius: sleepSkinTemperatureCelsius, deviationFromBaseLine: deviationFromBaseLine)
    }

    static func convertSnoozeTimeListToLocalTime(snoozeTimeList: [PbLocalDateTime]) throws -> [Date] {

        var snoozeTimes = [Date]()

        for snoozeTime in snoozeTimeList {

            let date = try PolarTimeUtils.pbLocalDateTimeToDate(pbLocalDateTime: snoozeTime)
            snoozeTimes.append(date)
        }

        return snoozeTimes
    }
}
