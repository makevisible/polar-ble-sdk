package com.polar.androidcommunications.api.ble.model.gatt.client.pmd

import io.mockk.MockKAnnotations
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class BlePmdClientControlPointResponseTest {

    @Before
    fun setUp() {
        MockKAnnotations.init(this)
    }

    @Test
    fun `success control point response for acc stream settings`() {
        //Arrange
        // HEX: F0 01 02 00 00 FF FF FF
        // index    type                                               data:
        // 0:       Response code                          size 1:     0xF0
        val expectedResponseCode = 0xF0.toByte()
        // 1:       Op code                                size 1:     0x01 (Request stream settings)
        val expectedOpCode = PmdControlPointCommandClientToService.GET_MEASUREMENT_SETTINGS
        // 2:       Measurement Type                       size 1:     0x02 (Acc)
        val expectedMeasurementType = 0x02.toByte()
        // 3:       Error Code                             size 1:     0x00 (Success)
        val expectedStatus =
            PmdControlPointResponse.PmdControlPointResponseCode.SUCCESS
        // 4:       More                                   size 1:     0x00 (No more)
        val expectedMore = false
        // 5..n:    Parameters                             size 3:     0xFF 0xFF 0xFF (some data)
        val expectedParamsSize = 3
        val expectedParamsContent = byteArrayOf(0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte())

        val cpResponse = byteArrayOf(
            0xF0.toByte(),
            0x01.toByte(),
            0x02.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0xFF.toByte(),
            0xFF.toByte(),
            0xFF.toByte()
        )

        //Act
        val response = PmdControlPointResponse(cpResponse)

        //Assert
        assertEquals(expectedResponseCode, response.responseCode)
        assertEquals(expectedOpCode, response.opCode)
        assertEquals(expectedMeasurementType, response.measurementType)
        assertEquals(expectedStatus, response.status)
        assertEquals(expectedMore, response.more)
        assertEquals(expectedParamsSize, response.parameters.size)
        assertTrue(expectedParamsContent.contentEquals(response.parameters))
    }

    @Test
    fun `derived measurement start fails with ERROR_INVALID_DERIVED_MEASUREMENT_SETTINGS_GROUP`() {
        // Verifies that the response F0 02 0F 11 00 (status=0x11=17) is parsed without
        // ArrayIndexOutOfBoundsException and maps to ERROR_INVALID_DERIVED_MEASUREMENT_SETTINGS_GROUP.
        // Regression test for error codes not present in the original enum.
        val cpResponse = byteArrayOf(
            0xF0.toByte(), // response code
            0x02.toByte(), // op code: REQUEST_MEASUREMENT_START
            0x0F.toByte(), // measurement type: DERIVED_MEASUREMENT (15)
            0x11.toByte(), // status: 0x11 = 17 = ERROR_INVALID_DERIVED_MEASUREMENT_SETTINGS_GROUP
            0x00.toByte()  // more: false
        )

        val response = PmdControlPointResponse(cpResponse)

        assertEquals(
            PmdControlPointResponse.PmdControlPointResponseCode.ERROR_INVALID_DERIVED_MEASUREMENT_SETTINGS_GROUP,
            response.status
        )
        assertEquals(PmdControlPointCommandClientToService.REQUEST_MEASUREMENT_START, response.opCode)
        assertEquals(false, response.more)
        assertEquals(0, response.parameters.size)
    }

    @Test
    fun `unknown future error code does not crash and maps to UNKNOWN_ERROR`() {
        // Verifies that a status byte beyond all known codes returns UNKNOWN_ERROR
        // instead of throwing ArrayIndexOutOfBoundsException.
        val cpResponse = byteArrayOf(
            0xF0.toByte(),
            0x02.toByte(),
            0x0F.toByte(),
            0x7F.toByte(), // some future unknown error code
            0x00.toByte()
        )

        val response = PmdControlPointResponse(cpResponse)

        assertEquals(
            PmdControlPointResponse.PmdControlPointResponseCode.UNKNOWN_ERROR,
            response.status
        )
    }

    @Test
    fun `failing control point response for mag stream settings`() {
        //Arrange
        // HEX: F0 01 06 00 00
        // index    type                                               data:
        // 0:       Response code                          size 1:     0xF0
        val expectedResponseCode = 0xF0.toByte()
        // 1:       Op code                                size 1:     0x01 (Request stream settings)
        val expectedOpCode = PmdControlPointCommandClientToService.GET_MEASUREMENT_SETTINGS
        // 2:       Measurement Type                       size 1:     0x06 (mag)
        val expectedMeasurementType = 0x06.toByte()
        // 3:       Error Code                             size 1:     0x07 (Failure)
        val expectedStatus =
            PmdControlPointResponse.PmdControlPointResponseCode.ERROR_INVALID_RESOLUTION
        // 4:       More                                   size 1:     0x00 (No more)
        val expectedMore = false
        // 5..n:    Parameters                             size 3:     0xFF 0xFF 0xFF (some data)
        val expectedParamsSize = 0
        val expectedParamsContent = byteArrayOf()

        val cpResponse =
            byteArrayOf(0xF0.toByte(), 0x01.toByte(), 0x06.toByte(), 0x07.toByte(), 0x00.toByte())

        //Act
        val response = PmdControlPointResponse(cpResponse)

        //Assert
        assertEquals(expectedResponseCode, response.responseCode)
        assertEquals(expectedOpCode, response.opCode)
        assertEquals(expectedMeasurementType, response.measurementType)
        assertEquals(expectedStatus, response.status)
        assertEquals(expectedMore, response.more)
        assertEquals(expectedParamsSize, response.parameters.size)
        assertTrue(expectedParamsContent.contentEquals(response.parameters))
    }
}