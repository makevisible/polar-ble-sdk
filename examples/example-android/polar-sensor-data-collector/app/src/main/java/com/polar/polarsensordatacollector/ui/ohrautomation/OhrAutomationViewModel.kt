package com.polar.polarsensordatacollector.ui.ohrautomation

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.polar.polarsensordatacollector.repository.PolarDeviceRepository
import com.polar.polarsensordatacollector.repository.ResultOfRequest
import com.polar.polarsensordatacollector.service.OhrAutomationService
import com.polar.polarsensordatacollector.ui.landing.ONLINE_OFFLINE_KEY_DEVICE_ID
import com.polar.sdk.api.model.LogConfig
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

enum class AutomationPhase {
    IDLE,
    ENABLING_OHR,
    WAITING,
    DISABLING_OHR,
    LISTING_FILES,
    DOWNLOADING,
    CLEANING,
    SAVING,
    CYCLE_COMPLETE,
    ERROR
}

data class AutomationUiState(
    val phase: AutomationPhase = AutomationPhase.IDLE,
    val remainingTimeMs: Long = 0L,
    val totalWaitTimeMs: Long = 0L,
    val cycleCount: Int = 0,
    val logLines: List<String> = emptyList(),
    val errorMessage: String? = null,
    val isRunning: Boolean = false,
    val currentFileProgress: String = ""
)

@HiltViewModel
class OhrAutomationViewModel @Inject constructor(
    private val repository: PolarDeviceRepository,
    @ApplicationContext private val appContext: Context,
    state: SavedStateHandle
) : ViewModel() {
    companion object {
        private const val TAG = "OhrAutomationVM"
        private const val PREFS_NAME = "ohr_automation_prefs"
        private const val PREF_IS_RUNNING = "is_running"
        private const val PREF_WAIT_DURATION_MS = "wait_duration_ms"
        private const val PREF_WAIT_STARTED_AT_MS = "wait_started_at_ms"
        private const val PREF_CYCLE_COUNT = "cycle_count"
        private val TARGET_FILES = listOf(
            "/SDLOGS/OHRLOG.SLG",
            "/SYSLOG.BPB",
            "/SYSLOG.TXT"
        )
        private const val TRC_PATTERN = "TRC"
        private const val TRC_EXTENSION = ".BIN"
    }

    private val deviceId = state.get<String>(ONLINE_OFFLINE_KEY_DEVICE_ID)
        ?: throw Exception("OhrAutomationViewModel must know the deviceId")

    private val prefs: SharedPreferences =
        appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _uiState = MutableStateFlow(AutomationUiState())
    val uiState: StateFlow<AutomationUiState> = _uiState.asStateFlow()

    private var activeJob: Job? = null
    private var stopRequested = false
    private var currentWaitDurationMs = 0L
    private val downloadedFiles = mutableMapOf<String, ByteArray>()

    init {
        checkForResumableSession()
    }

    // --- Per-device preference keys ---

    private fun prefKey(key: String): String = "${key}_${deviceId}"

    // --- Resume logic ---

    private fun checkForResumableSession() {
        val wasRunning = prefs.getBoolean(prefKey(PREF_IS_RUNNING), false)
        if (!wasRunning) return

        val waitDurationMs = prefs.getLong(prefKey(PREF_WAIT_DURATION_MS), 0L)
        val waitStartedAtMs = prefs.getLong(prefKey(PREF_WAIT_STARTED_AT_MS), 0L)
        val savedCycleCount = prefs.getInt(prefKey(PREF_CYCLE_COUNT), 0)

        if (waitDurationMs <= 0) {
            clearPersistedState()
            return
        }

        activeJob = viewModelScope.launch {
            addLog("🔍 Detected previous session, checking device state...")

            val logConfig = when (val result = repository.getLogConfig(deviceId)) {
                is ResultOfRequest.Success -> result.value
                is ResultOfRequest.Failure -> {
                    addLog("⚠️ Could not read log config: ${result.message}")
                    addLog("   Cannot resume — starting fresh when ready")
                    clearPersistedState()
                    stopService()
                    return@launch
                }
            }

            if (logConfig?.ohrLogEnabled != true) {
                addLog("ℹ️ OHR logging is no longer active on device. Previous session ended.")
                clearPersistedState()
                stopService()
                return@launch
            }

            val elapsed = System.currentTimeMillis() - waitStartedAtMs
            val remaining = waitDurationMs - elapsed

            stopRequested = false
            currentWaitDurationMs = waitDurationMs
            startService()
            _uiState.update {
                it.copy(
                    isRunning = true,
                    totalWaitTimeMs = waitDurationMs,
                    cycleCount = savedCycleCount,
                    errorMessage = null
                )
            }

            if (remaining > 0) {
                addLog("▶️ Resuming cycle (${formatTime(remaining)} remaining)")
                setPhase(AutomationPhase.WAITING)
                addLog("⏳ Continuing wait...")
                persistWaitStart(waitStartedAtMs)
                waitForDuration(remaining)
                if (stopRequested) return@launch
                proceedAfterWait(waitDurationMs)
            } else {
                addLog("▶️ Wait time elapsed while app was away. Proceeding to download...")
                proceedAfterWait(waitDurationMs)
            }
        }
    }

    // --- Public actions ---

    fun start(waitHours: Int, waitMinutes: Int) {
        val totalMs = ((waitHours * 60L) + waitMinutes) * 60L * 1000L
        if (totalMs <= 0) {
            addLog("⚠️ Please set a wait duration > 0")
            return
        }
        stopRequested = false
        currentWaitDurationMs = totalMs
        startService()
        _uiState.update {
            it.copy(
                isRunning = true,
                totalWaitTimeMs = totalMs,
                cycleCount = 0,
                logLines = emptyList(),
                errorMessage = null
            )
        }
        addLog("🚀 Starting OHR automation cycle (wait: ${waitHours}h ${waitMinutes}m)")
        runCycle(totalMs)
    }

    fun stop() {
        stopRequested = true
        activeJob?.cancel()
        activeJob = null
        clearPersistedState()
        stopService()
        addLog("🛑 Automation stopped by user")
        _uiState.update {
            it.copy(
                phase = AutomationPhase.IDLE,
                isRunning = false,
                remainingTimeMs = 0L
            )
        }
    }

    /**
     * Stop the automation loop but still run one final download/cleanup cycle
     * (disable OHR → list → download → remove OHRLOG → save).
     */
    fun stopAndFetch() {
        stopRequested = true
        activeJob?.cancel()
        activeJob = null
        clearPersistedState()
        addLog("🛑 Stopping automation, running final fetch cycle...")

        // Reset stopRequested so the fetch cycle can run
        stopRequested = false

        _uiState.update {
            it.copy(remainingTimeMs = 0L)
        }

        activeJob = viewModelScope.launch {
            try {
                proceedAfterWait(currentWaitDurationMs, isFinalCycle = true)
            } catch (e: CancellationException) {
                // Coroutine cancelled, no error to report
            } catch (e: Exception) {
                handleError("Unexpected error during final fetch: ${e.message}")
            }
        }
    }

    // --- Cycle logic ---

    private fun runCycle(waitTimeMs: Long) {
        if (stopRequested) return
        activeJob = viewModelScope.launch {
            try {
                // Step 1: Enable OHR logging
                setPhase(AutomationPhase.ENABLING_OHR)
                addLog("📡 Enabling OHR logging...")
                val currentConfig = when (val result = repository.getLogConfig(deviceId)) {
                    is ResultOfRequest.Success -> result.value ?: LogConfig()
                    is ResultOfRequest.Failure -> LogConfig()
                }
                val enableResult = repository.setLogConfig(
                    deviceId,
                    currentConfig.copy(ohrLogEnabled = true)
                )
                if (enableResult is ResultOfRequest.Failure) {
                    handleError("Failed to enable OHR logging: ${enableResult.message}")
                    return@launch
                }
                addLog("✅ OHR logging enabled")

                if (stopRequested) return@launch

                // Step 2: Wait
                setPhase(AutomationPhase.WAITING)
                addLog("⏳ Waiting ${formatTime(waitTimeMs)}...")
                persistRunningState(waitTimeMs)
                waitForDuration(waitTimeMs)
                if (stopRequested) return@launch

                proceedAfterWait(waitTimeMs)

            } catch (e: CancellationException) {
                // Coroutine cancelled by stop(), not an error
            } catch (e: Exception) {
                handleError("Unexpected error: ${e.message}")
            }
        }
    }

    /**
     * Post-wait cycle: disable OHR, list/download files, clean up, save.
     * @param isFinalCycle if true, go to IDLE instead of restarting.
     */
    private suspend fun proceedAfterWait(waitTimeMs: Long, isFinalCycle: Boolean = false) {
        try {
            // Step 3: Disable OHR logging
            setPhase(AutomationPhase.DISABLING_OHR)
            addLog("📡 Disabling OHR logging...")
            val currentConfig = when (val result = repository.getLogConfig(deviceId)) {
                is ResultOfRequest.Success -> result.value ?: LogConfig()
                is ResultOfRequest.Failure -> LogConfig()
            }
            val disableResult = repository.setLogConfig(
                deviceId,
                currentConfig.copy(ohrLogEnabled = false)
            )
            if (disableResult is ResultOfRequest.Failure) {
                handleError("Failed to disable OHR logging: ${disableResult.message}")
                return
            }
            addLog("✅ OHR logging disabled")

            // Step 4: List files
            setPhase(AutomationPhase.LISTING_FILES)
            addLog("📂 Listing files on band...")
            val allFiles = mutableListOf<Pair<String, Long>>()
            try {
                repository.dumpAllFiles(deviceId)
                    .catch { e ->
                        addLog("⚠️ Error during file listing: ${e.message}")
                    }
                    .toList(allFiles)
            } catch (e: Exception) {
                handleError("Failed to list files: ${e.message}")
                return
            }
            addLog("✅ Found ${allFiles.size} files on band")

            // Step 5: Download target files
            setPhase(AutomationPhase.DOWNLOADING)
            downloadedFiles.clear()

            val trcFiles = allFiles.filter { (path, _) ->
                val name = path.substringAfterLast("/")
                name.startsWith(TRC_PATTERN) && name.endsWith(TRC_EXTENSION)
            }

            val filesToDownload = TARGET_FILES.toMutableList()
            trcFiles.forEach { (path, _) -> filesToDownload.add(path) }

            for (filePath in filesToDownload) {
                val fileExists = allFiles.any { it.first == filePath }
                if (!fileExists) {
                    addLog("⏭️ File not found on band: $filePath, skipping")
                    continue
                }

                _uiState.update { it.copy(currentFileProgress = filePath) }
                addLog("📥 Downloading $filePath...")
                when (val result = repository.getFile(deviceId, filePath)) {
                    is ResultOfRequest.Success -> {
                        result.value?.let { bytes ->
                            downloadedFiles[filePath] = bytes
                            addLog("✅ Downloaded $filePath (${bytes.size} bytes)")
                        }
                    }
                    is ResultOfRequest.Failure -> {
                        addLog("⚠️ Failed to download $filePath: ${result.message}")
                    }
                }
            }

            // Step 6: Remove OHRLOG.SLG
            setPhase(AutomationPhase.CLEANING)
            val ohrLogPath = "/SDLOGS/OHRLOG.SLG"
            if (downloadedFiles.containsKey(ohrLogPath)) {
                addLog("🗑️ Removing $ohrLogPath from band...")
                when (val result = repository.removeSingleFile(deviceId, ohrLogPath)) {
                    is ResultOfRequest.Success -> {
                        addLog("✅ Removed $ohrLogPath")
                    }
                    is ResultOfRequest.Failure -> {
                        addLog("⚠️ Failed to remove $ohrLogPath: ${result.message}")
                    }
                }
            }

            // Step 7: Save files to external storage
            setPhase(AutomationPhase.SAVING)
            addLog("💾 Saving files to storage...")
            saveFilesToStorage()
            addLog("✅ Files saved to storage")

            if (isFinalCycle) {
                // Final cycle — go to IDLE
                val newCycleCount = _uiState.value.cycleCount + 1
                addLog("✅ Final fetch cycle complete (total cycles: $newCycleCount)")
                stopService()
                _uiState.update {
                    it.copy(
                        phase = AutomationPhase.IDLE,
                        cycleCount = newCycleCount,
                        currentFileProgress = "",
                        isRunning = false
                    )
                }
                return
            }

            // Cycle complete — restart
            val newCycleCount = _uiState.value.cycleCount + 1
            _uiState.update {
                it.copy(
                    phase = AutomationPhase.CYCLE_COMPLETE,
                    cycleCount = newCycleCount,
                    currentFileProgress = ""
                )
            }
            addLog("🔄 Cycle $newCycleCount complete. Restarting...")

            if (stopRequested) return

            runCycle(waitTimeMs)

        } catch (e: CancellationException) {
            // Coroutine cancelled by stop(), not an error
        } catch (e: Exception) {
            handleError("Unexpected error: ${e.message}")
        }
    }

    // --- Coroutine-based timer (survives screen-off with WakeLock) ---

    /**
     * Suspends for [durationMs], updating the UI every second.
     * Uses coroutine [delay] instead of CountDownTimer, so it works
     * reliably when the screen is off (as long as the foreground service
     * holds a WakeLock).
     */
    private suspend fun waitForDuration(durationMs: Long) {
        val endTime = System.currentTimeMillis() + durationMs
        while (true) {
            val remaining = endTime - System.currentTimeMillis()
            if (remaining <= 0) break
            _uiState.update { it.copy(remainingTimeMs = remaining) }
            // Sleep for 1 second or whatever is remaining, whichever is shorter
            delay(minOf(1000L, remaining))
        }
        _uiState.update { it.copy(remainingTimeMs = 0L) }
    }

    private suspend fun saveFilesToStorage() {
        withContext(Dispatchers.IO) {
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val baseDir = File(appContext.getExternalFilesDir(null), "polar_ohr_logs/$timestamp")
            baseDir.mkdirs()

            for ((filePath, bytes) in downloadedFiles) {
                val fileName = filePath.substringAfterLast("/")
                val outFile = File(baseDir, fileName)
                try {
                    outFile.writeBytes(bytes)
                    addLog("   Saved: ${outFile.absolutePath}")
                } catch (e: Exception) {
                    addLog("   ⚠️ Failed to save $fileName: ${e.message}")
                }
            }
        }
    }

    // --- Service helpers ---

    private fun startService() {
        try {
            OhrAutomationService.startService(appContext)
        } catch (e: Exception) {
            Log.w(TAG, "Could not start foreground service: ${e.message}")
        }
    }

    private fun stopService() {
        try {
            OhrAutomationService.stopService(appContext)
        } catch (e: Exception) {
            Log.w(TAG, "Could not stop foreground service: ${e.message}")
        }
    }

    // --- Persistence helpers (per-device keys) ---

    private fun persistRunningState(waitDurationMs: Long) {
        persistWaitStart(System.currentTimeMillis())
        prefs.edit()
            .putBoolean(prefKey(PREF_IS_RUNNING), true)
            .putLong(prefKey(PREF_WAIT_DURATION_MS), waitDurationMs)
            .putInt(prefKey(PREF_CYCLE_COUNT), _uiState.value.cycleCount)
            .apply()
    }

    private fun persistWaitStart(startTimeMs: Long) {
        prefs.edit()
            .putLong(prefKey(PREF_WAIT_STARTED_AT_MS), startTimeMs)
            .apply()
    }

    private fun clearPersistedState() {
        prefs.edit()
            .remove(prefKey(PREF_IS_RUNNING))
            .remove(prefKey(PREF_WAIT_DURATION_MS))
            .remove(prefKey(PREF_WAIT_STARTED_AT_MS))
            .remove(prefKey(PREF_CYCLE_COUNT))
            .apply()
    }

    // --- UI helpers ---

    private fun setPhase(phase: AutomationPhase) {
        _uiState.update { it.copy(phase = phase, errorMessage = null) }
    }

    private fun handleError(message: String) {
        Log.e(TAG, message)
        addLog("❌ $message")
        clearPersistedState()
        stopService()
        _uiState.update {
            it.copy(
                phase = AutomationPhase.ERROR,
                errorMessage = message,
                isRunning = false
            )
        }
    }

    private fun addLog(message: String) {
        Log.d(TAG, message)
        _uiState.update {
            it.copy(logLines = it.logLines + message)
        }
    }

    private fun formatTime(ms: Long): String {
        val totalSeconds = ms / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
    }

    override fun onCleared() {
        super.onCleared()
        activeJob?.cancel()
    }
}
