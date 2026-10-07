package com.polar.androidcommunications.api.ble.model.gatt.client.pmd.model

import androidx.annotation.VisibleForTesting
import com.polar.androidcommunications.api.ble.exceptions.NegativeTimeStampError
import com.polar.androidcommunications.api.ble.exceptions.SampleSizeMissingError
import com.polar.androidcommunications.api.ble.exceptions.TimeStampAndFrequencyZeroError
import kotlin.math.round

internal object PmdTimeStampUtils {

    fun getTimeStamps(previousFrameTimeStamp: ULong, frameTimeStamp: ULong, samplesSize: Int, sampleRate: Int): List<ULong> {
        // guard
        if (samplesSize <= 0) {
            throw SampleSizeMissingError
        }

        // A device clock correction can place a frame behind its predecessor. The ULong subtraction
        // in deltaFromTimeStamps wraps rather than going negative, so the frame is spaced at the
        // nominal sample rate and anchored on frameTimeStamp, as the first frame of a recording is.
        val hasUsablePreviousFrame = previousFrameTimeStamp != 0uL && previousFrameTimeStamp < frameTimeStamp

        val timeStampDelta = getTimeStampDelta(previousFrameTimeStamp, frameTimeStamp, samplesSize, sampleRate, hasUsablePreviousFrame)

        // guard
        if (frameTimeStamp.toDouble() < (timeStampDelta * samplesSize.toDouble())) {
            throw NegativeTimeStampError("Sample time stamp calculation fails. The timestamps are negative, since frameTimeStamp $frameTimeStamp minus ${timeStampDelta * samplesSize} is negative")
        }

        val startTimeStamp = if (hasUsablePreviousFrame) {
            firstSampleTimeFromTimeStamps(previousFrameTimeStamp, timeStampDelta)
        } else {
            firstSampleTimeFromSampleRate(frameTimeStamp, timeStampDelta, samplesSize)
        }

        val timeStampList = MutableList(size = samplesSize - 1, init = { index ->
            round(startTimeStamp + timeStampDelta * index).toULong()
        })
        timeStampList.add(frameTimeStamp)
        return timeStampList
    }

    private fun getTimeStampDelta(previousFrameTimeStamp: ULong, timeStamp: ULong, samplesSize: Int, sampleRate: Int, hasUsablePreviousFrame: Boolean): Double {
        // guard
        if (!hasUsablePreviousFrame && sampleRate <= 0) {
            throw TimeStampAndFrequencyZeroError("Timestamp delta cannot be calculated for the frame, because previousTimeStamp $previousFrameTimeStamp timestamp $timeStamp and sampleRate $sampleRate")
        }

        val delta = if (hasUsablePreviousFrame) {
            deltaFromTimeStamps(previousFrameTimeStamp, timeStamp, samplesSize)
        } else {
            deltaFromSamplingRate(sampleRate)
        }
        return delta
    }

    @VisibleForTesting
    fun deltaFromSamplingRate(samplingRate: Int): Double {
        return (1.0 / samplingRate.toDouble()) * 1000 * 1000 * 1000
    }

    fun deltaFromTimeStamps(previousTimeStamp: ULong, timeStamp: ULong, samples: Int): Double {
        // Compared before subtracting: ULong arithmetic wraps instead of going negative.
        if (timeStamp <= previousTimeStamp) {
            throw NegativeTimeStampError("Failed to decide delta from when previous timestamp: $previousTimeStamp timestamp: $timeStamp")
        }
        return (timeStamp - previousTimeStamp).toDouble() / samples.toDouble()
    }

    private fun firstSampleTimeFromTimeStamps(previousTimeStamp: ULong, timeStampDelta: Double): Double {
        return previousTimeStamp.toDouble() + timeStampDelta
    }

    private fun firstSampleTimeFromSampleRate(lastSampleTimeStamp: ULong, timeStampDelta: Double, samplesSize: Int): Double {
        return if (samplesSize > 0) {
            val startTimeStamp = lastSampleTimeStamp.toDouble() - (timeStampDelta * (samplesSize - 1))
            if (startTimeStamp > 0) {
                startTimeStamp
            } else {
                throw NegativeTimeStampError("Failed to estimate first sample timestamp when timeStamp: $lastSampleTimeStamp delta: $timeStampDelta size: $samplesSize")
            }
        } else {
            throw NegativeTimeStampError("Failed to estimate first sample timestamp when timeStamp: $lastSampleTimeStamp delta: $timeStampDelta size: $samplesSize")
        }
    }
}