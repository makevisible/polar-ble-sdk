// Copyright © 2024 Polar Electro Oy. All rights reserved.
package com.polar.sdk.api

import com.polar.sdk.api.model.FirmwareUpdateStatus
import io.reactivex.rxjava3.core.Flowable
import com.polar.sdk.api.model.PolarFirmwareVersionInfo

/**
 * Polar firmware update API.
 *
 * Requires feature [FEATURE_POLAR_FIRMWARE_UPDATE]
 *
 */
interface PolarFirmwareUpdateApi {
    /**
     * Updates firmware to given device from local file.
     *
     * @param identifier Polar device ID or BT address
     * @param filePath path to the file
     * @return [Flowable] emitting status of firmware update
     */
    fun updateFirmwareLocal(identifier: String, filePath: String): Flowable<FirmwareUpdateStatus>

    /**
     * Updates firmware to given device.
     *
     * @param identifier Polar device ID or BT address
     * @return [Flowable] emitting status of firmware update
     */
    fun updateFirmware(identifier: String): Flowable<FirmwareUpdateStatus>

    fun getFirmwareInfo(identifier: String): PolarFirmwareVersionInfo?
}