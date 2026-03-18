package com.polar.polarsensordatacollector.ui.h10exercise

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.GsonBuilder
import com.polar.polarsensordatacollector.repository.H10ExerciseRepository
import com.polar.polarsensordatacollector.service.H10AutomationService
import com.polar.polarsensordatacollector.ui.landing.ONLINE_OFFLINE_KEY_DEVICE_ID
import com.polar.sdk.api.model.PolarExerciseData
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.disposables.CompositeDisposable
import io.reactivex.rxjava3.schedulers.Schedulers
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

enum class H10AutomationPhase {
    IDLE,
    STARTING_RECORDING,
    WAITING,
    STOPPING_RECORDING,
    FETCHING,
    CLEANING,
    SAVING,
    CYCLE_COMPLETE,
    ERROR
}

data class H10AutomationUiState(
    val phase: H10AutomationPhase = H10AutomationPhase.IDLE,
    val remainingTimeMs: Long = 0L,
    val totalWaitTimeMs: Long = 0L,
    val cycleCount: Int = 0,
    val logLines: List<String> = emptyList(),
    val errorMessage: String? = null,
    val isRunning: Boolean = false
)

private const val TAG = "H10ExerciseViewModel"
private const val PREFS_NAME = "h10_automation_prefs"
private const val PREF_IS_RUNNING = "is_running"
private const val PREF_WAIT_DURATION_MS = "wait_duration_ms"
private const val PREF_WAIT_STARTED_AT_MS = "wait_started_at_ms"
private const val PREF_CYCLE_COUNT = "cycle_count"

@HiltViewModel
class H10ExerciseViewModel @Inject constructor(
    private val repository: H10ExerciseRepository,
    @ApplicationContext private val appContext: Context,
    state: SavedStateHandle
) : ViewModel() {

    private val deviceId =
        state.get<String>(ONLINE_OFFLINE_KEY_DEVICE_ID)
            ?: throw Exception("Device settings viewModel must know the deviceId")

    private val prefs: SharedPreferences =
        appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val disposables = CompositeDisposable()

    private val _statusText = MutableStateFlow("")

    val featureState = repository.featureState

    // Automation UI State
    private val _autoUiState = MutableStateFlow(H10AutomationUiState())
    val autoUiState: StateFlow<H10AutomationUiState> = _autoUiState.asStateFlow()

    private var activeJob: Job? = null
    private var stopRequested = false
    private var skipWaitRequested = false
    private var currentWaitDurationMs = 0L
    private val logTimeFmt = SimpleDateFormat("HH:mm:ss", Locale.US)

    /** Persistent log file that spans all cycles for this device */
    private val logFile: File by lazy {
        val dir = File(appContext.getExternalFilesDir(null), "polar_h10_logs")
        dir.mkdirs()
        val time = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US).format(Date())
        File(dir, "h10_automation_log_${deviceId}_${time}.txt")
    }

    init {
        _statusText.value = ""
        val disposable = repository.requestRecordingStatus(deviceId)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe({ pair ->
                val isRecording = pair.first == true
                val activeExerciseId = pair.second ?: ""
                Log.d(TAG, "requestRecordingStatus result: isRecording=$isRecording, entryId=$activeExerciseId")
                
                repository.updateStatus(isSupported = true, isEnabled = isRecording)
                
                // Check if automation was running or if we resumed with an active exercise
                if (isRecording) {
                    addLog("ℹ️ Device connected with an active recording (ID: $activeExerciseId)")
                }
                checkForResumableSession(isRecording)
            }, { e ->
                Log.e(TAG, "requestRecordingStatus() failed", e)
                addLog("⚠️ Failed to check recording status: ${e.message}")
                checkForResumableSession(false)
            })
        disposables.add(disposable)
    }

    // --- Original Manual UI Methods ---

    fun listExercises(onResult: (Int) -> Unit, onError: () -> Unit) {
        val disposable = repository.listExercises(deviceId)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe({ entries ->
                onResult(entries.size)
            }, { e ->
                Log.e(TAG, "listExercises() failed", e)
                onError()
            })
        disposables.add(disposable)
    }

    fun readFirstExercise(
        onExercise: (PolarExerciseData) -> Unit,
        onError: () -> Unit
    ) {
        val disposable = repository.listExercises(deviceId)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .flatMap { list ->
                if (list.isNotEmpty()) {
                    repository.readExercise(deviceId, list.first())
                } else {
                    io.reactivex.rxjava3.core.Single.error(Exception("No exercises"))
                }
            }
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe({ exercise ->
                onExercise(exercise)
            }, { e ->
                Log.e(TAG, "readFirstExercise() failed", e)
                onError()
            })
        disposables.add(disposable)
    }

    fun removeFirstExercise(onComplete: () -> Unit, onError: () -> Unit) {
        val disposable = repository.listExercises(deviceId)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .flatMapCompletable { list ->
                if (list.isNotEmpty()) {
                    repository.removeExercise(deviceId, list.first())
                } else {
                    io.reactivex.rxjava3.core.Completable.error(Exception("No exercises"))
                }
            }
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe({
                onComplete()
            }, { e ->
                Log.e(TAG, "removeFirstExercise() failed", e)
                onError()
            })
        disposables.add(disposable)
    }

    fun toggleRecording() {
        val feature = featureState.value
        val disposable = if (feature.isEnabled) {
            repository.stopRecording(deviceId)
        } else {
            val exerciseId = "H10_EX_${System.currentTimeMillis()}"
            Log.i(TAG, "Starting H10 exercise recording. Exercise ID: $exerciseId, Start time: ${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", java.util.Locale.getDefault()).format(java.util.Date())}")
            repository.startRecording(deviceId, exerciseId)
        }
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .doOnComplete {
                repository.updateRecordingEnabled(!feature.isEnabled)
            }
            .subscribe({}, { e ->
                Log.e(TAG, "toggleRecording() failed", e)
            })
        disposables.add(disposable)
    }


    // --- Automation Persistence ---

    private fun prefKey(key: String): String = "${key}_${deviceId}"

    private fun persistRunningState(waitDurationMs: Long) {
        prefs.edit()
            .putBoolean(prefKey(PREF_IS_RUNNING), true)
            .putLong(prefKey(PREF_WAIT_DURATION_MS), waitDurationMs)
            .putLong(prefKey(PREF_WAIT_STARTED_AT_MS), System.currentTimeMillis())
            .putInt(prefKey(PREF_CYCLE_COUNT), _autoUiState.value.cycleCount)
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

    private fun checkForResumableSession(isExerciseActive: Boolean) {
        val wasRunning = prefs.getBoolean(prefKey(PREF_IS_RUNNING), false)
        if (!wasRunning) {
            // If we weren't running automation, but an exercise is active, we just log it and do nothing special
            return
        }

        val waitDurationMs = prefs.getLong(prefKey(PREF_WAIT_DURATION_MS), 0L)
        val waitStartedAtMs = prefs.getLong(prefKey(PREF_WAIT_STARTED_AT_MS), 0L)
        val savedCycleCount = prefs.getInt(prefKey(PREF_CYCLE_COUNT), 0)

        if (waitDurationMs <= 0 || !isExerciseActive) {
            addLog("⚠️ Automation was marked as running, but exercise is no longer active. Resetting state.")
            clearPersistedState()
            return
        }

        activeJob = viewModelScope.launch {
            addLog("🔍 Detected previous automation session resuming...")
            val elapsed = System.currentTimeMillis() - waitStartedAtMs
            val remaining = waitDurationMs - elapsed

            stopRequested = false
            currentWaitDurationMs = waitDurationMs
            startService()

            _autoUiState.update {
                it.copy(
                    isRunning = true,
                    totalWaitTimeMs = waitDurationMs,
                    cycleCount = savedCycleCount,
                    errorMessage = null
                )
            }

            if (remaining > 0) {
                addLog("▶️ Resuming cycle (${formatTime(remaining)} remaining)")
                setPhase(H10AutomationPhase.WAITING)
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

    // --- Automation Public Actions ---

    fun startAutomation(waitHours: Int, waitMinutes: Int) {
        val totalMs = ((waitHours * 60L) + waitMinutes) * 60L * 1000L
        if (totalMs <= 0) {
            addLog("⚠️ Please set a wait duration > 0")
            return
        }
        
        stopRequested = false
        currentWaitDurationMs = totalMs
        startService()
        _autoUiState.update {
            it.copy(
                isRunning = true,
                totalWaitTimeMs = totalMs,
                cycleCount = 0,
                logLines = emptyList(),
                errorMessage = null
            )
        }
        addLog("🚀 Starting H10 automation cycle (wait: ${waitHours}h ${waitMinutes}m)")
        runCycle(totalMs, doInitialCleanup = true)
    }

    fun stopAutomation() {
        stopRequested = true
        skipWaitRequested = true
        activeJob?.cancel()
        activeJob = null
        clearPersistedState()
        stopService()
        
        // Stop the recording if we are interrupting an active cycle
        if (featureState.value.isEnabled) {
            addLog("🛑 Automation stopped. Stopping active exercise recording...")
            toggleRecording() // Safely toggle it off
        } else {
            addLog("🛑 Automation stopped.")
        }

        _autoUiState.update {
            it.copy(
                phase = H10AutomationPhase.IDLE,
                isRunning = false,
                remainingTimeMs = 0L
            )
        }
    }

    fun skipWait() {
        if (_autoUiState.value.phase != H10AutomationPhase.WAITING) return
        addLog("⏩ Skipping wait, proceeding to download...")
        skipWaitRequested = true
    }

    fun stopAndFetch() {
        stopRequested = true
        skipWaitRequested = true
        activeJob?.cancel()
        activeJob = null
        clearPersistedState()
        addLog("🛑 Stopping automation, running final fetch cycle...")

        // Reset stopRequested so the fetch cycle can run
        stopRequested = false

        _autoUiState.update {
            it.copy(remainingTimeMs = 0L)
        }

        activeJob = viewModelScope.launch {
            try {
                proceedAfterWait(currentWaitDurationMs, isFinalCycle = true)
            } catch (e: CancellationException) {
                // Ignore
            } catch (e: Exception) {
                handleError("Unexpected error during final fetch: ${e.message}")
            }
        }
    }

    // --- Automation Cycle Logic ---

    private suspend fun cleanupAndFetchExisting() {
        if (featureState.value.isEnabled) {
            setPhase(H10AutomationPhase.STOPPING_RECORDING)
            addLog("📡 Stopping active recording...")
            try {
                suspendCoroutine<Unit> { cont ->
                    repository.stopRecording(deviceId)
                        .subscribeOn(Schedulers.io())
                        .subscribe({
                            repository.updateRecordingEnabled(false)
                            cont.resume(Unit)
                        }, { e ->
                            cont.resumeWithException(e)
                        })
                }
                addLog("✅ Recording Stopped")
            } catch (e: Exception) {
                addLog("⚠️ Could not stop recording: ${e.message}")
            }
        }

        setPhase(H10AutomationPhase.FETCHING)
        addLog("📂 Listing exercises on band...")
        val entries = try {
            suspendCoroutine<List<com.polar.sdk.api.model.PolarExerciseEntry>> { cont ->
                repository.listExercises(deviceId)
                    .subscribeOn(Schedulers.io())
                    .subscribe({ list ->
                        cont.resume(list)
                    }, { e ->
                        cont.resumeWithException(e)
                    })
            }
        } catch (e: Exception) {
            addLog("⚠️ Failed to list exercises: ${e.message}")
            emptyList()
        }
        
        if (entries.isEmpty()) {
            addLog("⚠️ No exercises found on band.")
        } else {
            addLog("✅ Found ${entries.size} exercises. Fetching all...")
            
            for ((index, exerciseToFetch) in entries.withIndex()) {
                addLog("🔄 Fetching exercise ${index + 1}/${entries.size} (${exerciseToFetch.path})...")
                try {
                    val exerciseData = suspendCoroutine<com.polar.sdk.api.model.PolarExerciseData> { cont ->
                        repository.readExercise(deviceId, exerciseToFetch)
                            .subscribeOn(Schedulers.io())
                            .subscribe({ data ->
                                cont.resume(data)
                            }, { e ->
                                cont.resumeWithException(e)
                            })
                    }
                    addLog("✅ Fetched: ${exerciseData.hrSamples.size} HR samples")
                    
                    setPhase(H10AutomationPhase.SAVING)
                    addLog("💾 Saving data locally...")
                    saveExerciseToStorage(exerciseToFetch.path, exerciseData)

                    setPhase(H10AutomationPhase.CLEANING)
                    addLog("🗑️ Removing exercise from band...")
                    suspendCoroutine<Unit> { cont ->
                        repository.removeExercise(deviceId, exerciseToFetch)
                            .subscribeOn(Schedulers.io())
                            .subscribe({
                                cont.resume(Unit)
                            }, { e ->
                                cont.resumeWithException(e)
                            })
                    }
                    addLog("✅ Exercise removed.")
                } catch (e: Exception) {
                    addLog("⚠️ Error processing exercise ${exerciseToFetch.path}: ${e.message}")
                }
            }
        }
    }

    private fun runCycle(waitTimeMs: Long, doInitialCleanup: Boolean = false) {
        if (stopRequested) return
        activeJob = viewModelScope.launch {
            try {
                if (doInitialCleanup) {
                    addLog("🧹 Performing initial check/cleanup of band...")
                    cleanupAndFetchExisting()
                    if (stopRequested) return@launch
                }

                // Step 1: Start Recording
                setPhase(H10AutomationPhase.STARTING_RECORDING)
                val exerciseId = "H10_EX_${System.currentTimeMillis()}"
                addLog("📡 Starting exercise recording [ID: $exerciseId]...")
                
                suspendCoroutine { cont ->
                    repository.startRecording(deviceId, exerciseId)
                        .subscribeOn(Schedulers.io())
                        .subscribe({
                            repository.updateRecordingEnabled(true)
                            cont.resume(Unit)
                        }, { e ->
                            cont.resumeWithException(e)
                        })
                }
                addLog("✅ Recording Started")

                if (stopRequested) return@launch

                // Step 2: Wait
                setPhase(H10AutomationPhase.WAITING)
                addLog("⏳ Waiting ${formatTime(waitTimeMs)}...")
                skipWaitRequested = false
                persistRunningState(waitTimeMs)
                waitForDuration(waitTimeMs)
                if (stopRequested) return@launch

                proceedAfterWait(waitTimeMs)

            } catch (e: CancellationException) {
                // Ignore
            } catch (e: Exception) {
                handleError("Failed to start recording: ${e.message}")
            }
        }
    }

    private suspend fun proceedAfterWait(waitTimeMs: Long, isFinalCycle: Boolean = false) {
        try {
            cleanupAndFetchExisting()

            if (isFinalCycle) {
                // Final cycle — go to IDLE
                val newCycleCount = _autoUiState.value.cycleCount + 1
                addLog("✅ Final fetch cycle complete (total cycles: $newCycleCount)")
                stopService()
                _autoUiState.update {
                    it.copy(
                        phase = H10AutomationPhase.IDLE,
                        cycleCount = newCycleCount,
                        isRunning = false
                    )
                }
                return
            }

            // Cycle complete — restart
            val newCycleCount = _autoUiState.value.cycleCount + 1
            _autoUiState.update {
                it.copy(
                    phase = H10AutomationPhase.CYCLE_COMPLETE,
                    cycleCount = newCycleCount
                )
            }
            addLog("🔄 Cycle $newCycleCount complete. Restarting...")

            if (stopRequested) return

            runCycle(waitTimeMs)

        } catch (e: CancellationException) {
            // Ignore
        } catch (e: Exception) {
            handleError("Automation fetch/clean error: ${e.message}")
        }
    }

    private suspend fun waitForDuration(durationMs: Long) {
        val endTime = System.currentTimeMillis() + durationMs
        while (true) {
            if (skipWaitRequested) {
                skipWaitRequested = false
                break
            }
            val remaining = endTime - System.currentTimeMillis()
            if (remaining <= 0) break
            _autoUiState.update { it.copy(remainingTimeMs = remaining) }
            delay(minOf(1000L, remaining))
        }
        _autoUiState.update { it.copy(remainingTimeMs = 0L) }
    }

    private suspend fun saveExerciseToStorage(path: String, exerciseData: PolarExerciseData) {
        withContext(Dispatchers.IO) {
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val baseDir = File(appContext.getExternalFilesDir(null), "polar_h10_logs/$timestamp")
            baseDir.mkdirs()

            try {
                val gson = GsonBuilder().setPrettyPrinting().create()
                val json = gson.toJson(
                    mapOf(
                        "path" to path,
                        "recordingInterval" to exerciseData.recordingInterval,
                        "hrSamples" to exerciseData.hrSamples
                    )
                )

                val safeName = path.replace("/", "_") + ".json"
                val outFile = File(baseDir, safeName)
                outFile.writeText(json)
                addLog("   Saved JSON: ${outFile.absolutePath}")
            } catch (e: Exception) {
                addLog("   ⚠️ Failed to save JSON: ${e.message}")
            }

            // Save current log to the cycle directory
            try {
                val logSnapshot = _autoUiState.value.logLines.joinToString("\n")
                File(baseDir, "h10_automation_log.txt").writeText(logSnapshot)
                addLog("   Saved log to ${baseDir.absolutePath}/h10_automation_log.txt")
            } catch (e: Exception) {
                addLog("   ⚠️ Failed to save log file: ${e.message}")
            }
        }
    }


    // --- Util ---

    private fun startService() {
        try {
            H10AutomationService.startService(appContext)
        } catch (e: Exception) {
            Log.w(TAG, "Could not start foreground service: ${e.message}")
        }
    }

    private fun stopService() {
        try {
            H10AutomationService.stopService(appContext)
        } catch (e: Exception) {
            Log.w(TAG, "Could not stop foreground service: ${e.message}")
        }
    }

    private fun setPhase(phase: H10AutomationPhase) {
        _autoUiState.update { it.copy(phase = phase, errorMessage = null) }
    }

    private fun handleError(message: String) {
        Log.e(TAG, message)
        addLog("❌ $message")
        clearPersistedState()
        stopService()
        
        // Safety check if we failed mid-recording, try to shut it off
        if (featureState.value.isEnabled) {
            val disposable = repository.stopRecording(deviceId)
                .subscribeOn(Schedulers.io())
                .subscribe({ repository.updateRecordingEnabled(false) }, {})
            disposables.add(disposable)
        }

        _autoUiState.update {
            it.copy(
                phase = H10AutomationPhase.ERROR,
                errorMessage = message,
                isRunning = false
            )
        }
    }

    private fun addLog(message: String) {
        val timestamped = "[${logTimeFmt.format(Date())}] $message"
        Log.d(TAG, message)
        _autoUiState.update {
            it.copy(logLines = it.logLines + timestamped)
        }
        try {
            logFile.appendText(timestamped + "\n")
        } catch (_: Exception) {
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
        disposables.clear()
    }
}