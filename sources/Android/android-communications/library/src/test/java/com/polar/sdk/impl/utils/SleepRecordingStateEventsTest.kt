package com.polar.sdk.impl.utils

import com.google.protobuf.ByteString
import com.polar.androidcommunications.api.ble.model.gatt.BleGattBase
import com.polar.androidcommunications.api.ble.model.gatt.BleGattTxInterface
import com.polar.androidcommunications.api.ble.model.gatt.client.psftp.BlePsFtpClient
import com.polar.androidcommunications.api.ble.model.gatt.client.psftp.BlePsFtpUtils
import com.polar.androidcommunications.testrules.BleLoggerTestRule
import com.polar.sdk.api.model.sleep.PolarSleepRecordingStatus
import com.polar.sdk.api.model.sleep.PolarSleepRecordingStatus.DISABLED
import com.polar.sdk.api.model.sleep.PolarSleepRecordingStatus.ENABLED
import com.polar.sdk.api.model.sleep.PolarSleepRecordingStatus.UNKNOWN
import io.mockk.every
import io.mockk.mockk
import io.reactivex.rxjava3.core.Completable
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import protocol.PftpNotification.PbPFtpDevToHostNotification
import protocol.PftpNotification.PbPftpDHRestApiEvent
import java.util.Optional
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Drives the real PS-FTP notification pump with sleep_recording_state REST events, the way
 * getSleepRecordingState reads them: subscribe, take the first state, dispose.
 */
internal class SleepRecordingStateEventsTest {
    @Rule
    @JvmField
    val bleLoggerTestRule = BleLoggerTestRule()

    private val identifier = "E468F621"
    private val device = Executors.newSingleThreadScheduledExecutor()
    private lateinit var client: BlePsFtpClient

    @Before
    fun setUp() {
        val txInterface = mockk<BleGattTxInterface>(relaxed = true)
        every { txInterface.isConnected } returns true
        client = BlePsFtpClient(txInterface)
        client.descriptorWritten(BlePsFtpUtils.RFC77_PFTP_D2H_CHARACTERISTIC, true, BleGattBase.ATT_SUCCESS)
    }

    @Test
    fun `every read in a session receives the state the device sends`() {
        repeat(3) { read ->
            assertEquals("read ${read + 1}", ENABLED, readStatus(deviceAnswers = "{\"enabled\":1}"))
        }
    }

    @Test
    fun `a read after a timed out read receives the state the device sends`() {
        assertEquals(null, readStatus(deviceAnswers = null))
        assertEquals(ENABLED, readStatus(deviceAnswers = "{\"enabled\":1}"))
    }

    @Test
    fun `a read after one whose result handler clears the thread interrupt receives the state the device sends`() {
        assertEquals(DISABLED, readStatus(deviceAnswers = "{\"enabled\":0}", onResult = { Thread.interrupted() }))
        assertEquals(ENABLED, readStatus(deviceAnswers = "{\"enabled\":1}"))
    }

    @Test
    fun `a state the device sends as soon as the subscribe request is written is received`() {
        val subscribeWrite = Completable.fromAction { sendSleepRecordingState("{\"enabled\":0}") }

        assertEquals(DISABLED, readStatus(deviceAnswers = null, onSubscribed = subscribeWrite))
    }

    @Test
    fun `a state event without enabled is unknown, not off`() {
        assertEquals(UNKNOWN, readStatus(deviceAnswers = "{}"))
    }

    /**
     * One read: the device answers [deviceAnswers] shortly after the read starts, or stays silent when null.
     * [onResult] runs on the thread that delivers the state, like the caller's own result handling.
     */
    private fun readStatus(
        deviceAnswers: String?,
        onSubscribed: Completable = Completable.complete(),
        onResult: () -> Unit = {},
    ): PolarSleepRecordingStatus? {
        deviceAnswers?.let { device.schedule({ sendSleepRecordingState(it) }, DEVICE_DELAY_MS, TimeUnit.MILLISECONDS) }
        return client.receiveRestApiEvents(identifier, onSubscribed)
            .map { events -> events.mapNotNull(::parseSleepRecordingStatus) }
            .filter { it.isNotEmpty() }
            .firstOrError()
            .map { statuses -> Optional.of(statuses.last()) }
            .doOnSuccess { onResult() }
            .timeout(READ_TIMEOUT_MS, TimeUnit.MILLISECONDS)
            .onErrorReturnItem(Optional.empty())
            .blockingGet()
            .orElse(null)
    }

    private fun sendSleepRecordingState(state: String) {
        val event = PbPftpDHRestApiEvent.newBuilder()
            .addEvent(ByteString.copyFromUtf8("{\"sleep_recording_state\":$state}"))
            .setUncompressed(true)
            .build()
            .toByteArray()
        val lastFrameHeader = (BlePsFtpUtils.RFC76_STATUS_LAST shl 1).toByte()
        val frame = byteArrayOf(lastFrameHeader, PbPFtpDevToHostNotification.REST_API_EVENT_VALUE.toByte()) + event
        client.processServiceData(BlePsFtpUtils.RFC77_PFTP_D2H_CHARACTERISTIC, frame, BleGattBase.ATT_SUCCESS, true)
    }

    private companion object {
        const val DEVICE_DELAY_MS = 200L
        const val READ_TIMEOUT_MS = 2_000L
    }
}
