package com.polar.sdk.impl.utils

import com.google.gson.JsonElement
import com.google.gson.JsonParser
import com.polar.sdk.api.model.sleep.PolarSleepRecordingStatus

internal const val SLEEP_RECORDING_STATE_EVENT = "sleep_recording_state"

/**
 * Status of one SLEEP.API REST event, or null when the event is not a sleep_recording_state event.
 * A missing or unrecognized enabled value is [PolarSleepRecordingStatus.UNKNOWN], never off.
 */
internal fun parseSleepRecordingStatus(json: String): PolarSleepRecordingStatus? {
    val root = runCatching { JsonParser().parse(json) }.getOrNull() ?: return null
    if (!root.isJsonObject) return null
    val state = root.asJsonObject.get(SLEEP_RECORDING_STATE_EVENT) ?: return null
    if (!state.isJsonObject) return PolarSleepRecordingStatus.UNKNOWN
    return sleepRecordingStatus(state.asJsonObject.get("enabled"))
}

private fun sleepRecordingStatus(enabled: JsonElement?): PolarSleepRecordingStatus {
    if (enabled == null || !enabled.isJsonPrimitive) return PolarSleepRecordingStatus.UNKNOWN
    val primitive = enabled.asJsonPrimitive
    val value = when {
        primitive.isBoolean -> primitive.asBoolean.toString()
        else -> primitive.asString.trim().lowercase()
    }
    return when (value) {
        "1", "true" -> PolarSleepRecordingStatus.ENABLED
        "0", "false" -> PolarSleepRecordingStatus.DISABLED
        else -> PolarSleepRecordingStatus.UNKNOWN
    }
}
