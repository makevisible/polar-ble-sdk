//  Copyright © 2022 Polar. All rights reserved.

import Foundation

internal class PmdTimeStampUtils {
    
    static func getTimeStamps(previousFrameTimeStamp: UInt64, frameTimeStamp: UInt64, samplesSize: UInt, sampleRate: UInt) throws -> [UInt64] {
        
        guard samplesSize > 0 else {
            throw BleGattException.gattDataError(description: "Timestamp calculation error, sample size is zero")
        }
        
        // A device clock correction can place a frame behind its predecessor. The frame is then
        // spaced at the nominal sample rate and anchored on frameTimeStamp, as the first frame of
        // a recording is.
        let hasUsablePreviousFrame = previousFrameTimeStamp > 0 && previousFrameTimeStamp < frameTimeStamp

        let timeStampDelta = try getTimeStampDelta(previousFrameTimeStamp, frameTimeStamp, samplesSize, sampleRate, hasUsablePreviousFrame)

        // guard
        guard (Double(frameTimeStamp) >= timeStampDelta * Double(samplesSize)) else {
            throw BleGattException.gattDataError(description: "Sample time stamp calculation fails. The timestamps are negative, since frameTimeStamp \(frameTimeStamp) minus \((UInt64(timeStampDelta) * UInt64(samplesSize))) is negative")
        }

        let startTimeStamp:Double
        if (hasUsablePreviousFrame) {
            startTimeStamp = firstSampleTimeFromTimeStamps(previousFrameTimeStamp, timeStampDelta)
        } else {
            startTimeStamp = try firstSampleTimeFromSampleRate(frameTimeStamp, timeStampDelta, samplesSize)
        }

        var timeStampList = [UInt64]()
        for i in 0..<(samplesSize - 1) {
            timeStampList.append(UInt64(round(startTimeStamp + timeStampDelta * Double(i))))
        }
        timeStampList.append(frameTimeStamp)
        return timeStampList
    }
    
    static func getTimeStampDelta(_ previousFrameTimeStamp: UInt64, _ timeStamp: UInt64, _ samplesSize: UInt, _ sampleRate: UInt, _ hasUsablePreviousFrame: Bool) throws -> Double {
        
        guard hasUsablePreviousFrame || sampleRate > 0 else {
            throw BleGattException.gattDataError(description: "Timestamp delta cannot be calculated for the frame, because previousTimeStamp \(previousFrameTimeStamp) timestamp \(timeStamp) and sampleRate \(sampleRate)")
        }
        
        if (hasUsablePreviousFrame) {
            return try deltaFromTimeStamps(previousFrameTimeStamp, timeStamp, samplesSize)
        } else {
            return deltaFromSamplingRate(sampleRate)
        }
    }
    
    internal static func deltaFromSamplingRate(_ samplingRate: UInt) -> Double {
        return (1.0 / Double(samplingRate)) * 1000 * 1000 * 1000
    }
    
    internal static func deltaFromTimeStamps(_ previousTimeStamp: UInt64, _ timeStamp: UInt64, _ samples: UInt) throws -> Double {
        // Compared before subtracting: UInt64 subtraction traps on underflow.
        guard timeStamp > previousTimeStamp else {
            throw BleGattException.gattDataError(description: "Failed to decide delta from when previous timestamp: \(previousTimeStamp) timestamp: \(timeStamp)")
        }
        return Double(timeStamp - previousTimeStamp) / Double(samples)
    }
    
    private static func firstSampleTimeFromSampleRate(_ lastSampleTimeStamp: UInt64, _ timeStampDelta: Double, _ samplesSize: UInt) throws -> Double {
          if (samplesSize > 0) {
             let startTimeStamp = Double(lastSampleTimeStamp) - (timeStampDelta * Double(samplesSize - 1))
             if (startTimeStamp > 0) {
                 return startTimeStamp
             } else {
                 throw BleGattException.gattDataError(description: "Failed to estimate first sample timestamp when timeStamp: \(lastSampleTimeStamp) delta: \(timeStampDelta) size: \(samplesSize)")
             }
         } else {
             throw BleGattException.gattDataError(description:"Failed to estimate first sample timestamp when timeStamp: \(lastSampleTimeStamp) delta: \(timeStampDelta) size: \(samplesSize)")
         }
     }
    
    private static func firstSampleTimeFromTimeStamps(_ previousTimeStamp: UInt64,_ timeStampDelta: Double) -> Double {
         return Double(previousTimeStamp) + timeStampDelta
     }
}
