package com.polar.polarsensordatacollector.ui.ohrautomation

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.NumberPicker
import android.widget.ScrollView
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.polar.polarsensordatacollector.R
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import java.util.Locale

@AndroidEntryPoint
class OhrAutomationFragment : Fragment(R.layout.fragment_ohr_automation) {

    private lateinit var hoursPicker: NumberPicker
    private lateinit var minutesPicker: NumberPicker
    private lateinit var startStopButton: Button
    private lateinit var stopAndFetchButton: Button
    private lateinit var statusText: TextView
    private lateinit var countdownText: TextView
    private lateinit var cycleCountText: TextView
    private lateinit var logText: TextView
    private lateinit var logScrollView: ScrollView
    private lateinit var durationPickerGroup: View

    private val viewModel: OhrAutomationViewModel by viewModels()

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupViews(view)

        viewLifecycleOwner.lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.uiState.collect { state ->
                    updateUi(state)
                }
            }
        }

        startStopButton.setOnClickListener {
            if (viewModel.uiState.value.isRunning) {
                viewModel.stop()
            } else {
                viewModel.start(hoursPicker.value, minutesPicker.value)
            }
        }

        stopAndFetchButton.setOnClickListener {
            viewModel.stopAndFetch()
        }
    }

    private fun setupViews(view: View) {
        hoursPicker = view.findViewById(R.id.hours_picker)
        minutesPicker = view.findViewById(R.id.minutes_picker)
        startStopButton = view.findViewById(R.id.start_stop_button)
        stopAndFetchButton = view.findViewById(R.id.stop_and_fetch_button)
        statusText = view.findViewById(R.id.status_text)
        countdownText = view.findViewById(R.id.countdown_text)
        cycleCountText = view.findViewById(R.id.cycle_count_text)
        logText = view.findViewById(R.id.log_text)
        logScrollView = view.findViewById(R.id.log_scroll_view)
        durationPickerGroup = view.findViewById(R.id.duration_picker_group)

        hoursPicker.minValue = 0
        hoursPicker.maxValue = 12
        hoursPicker.value = 3

        minutesPicker.minValue = 0
        minutesPicker.maxValue = 59
        minutesPicker.value = 0
    }

    private fun updateUi(state: AutomationUiState) {
        // Start/Stop button
        startStopButton.text = if (state.isRunning) {
            getString(R.string.ohr_auto_stop)
        } else {
            getString(R.string.ohr_auto_start)
        }

        // Duration picker visibility
        durationPickerGroup.visibility = if (state.isRunning) View.GONE else View.VISIBLE

        // Stop & Fetch button visibility (only while running)
        stopAndFetchButton.visibility = if (state.isRunning) View.VISIBLE else View.GONE

        // Status text
        statusText.text = when (state.phase) {
            AutomationPhase.IDLE -> getString(R.string.ohr_auto_status_idle)
            AutomationPhase.ENABLING_OHR -> getString(R.string.ohr_auto_status_enabling)
            AutomationPhase.WAITING -> getString(R.string.ohr_auto_status_waiting)
            AutomationPhase.DISABLING_OHR -> getString(R.string.ohr_auto_status_disabling)
            AutomationPhase.LISTING_FILES -> getString(R.string.ohr_auto_status_listing)
            AutomationPhase.DOWNLOADING -> getString(R.string.ohr_auto_status_downloading, state.currentFileProgress)
            AutomationPhase.CLEANING -> getString(R.string.ohr_auto_status_cleaning)
            AutomationPhase.SAVING -> getString(R.string.ohr_auto_status_saving)
            AutomationPhase.CYCLE_COMPLETE -> getString(R.string.ohr_auto_status_cycle_complete)
            AutomationPhase.ERROR -> getString(R.string.ohr_auto_status_error, state.errorMessage ?: "Unknown")
        }

        // Countdown
        if (state.phase == AutomationPhase.WAITING) {
            countdownText.visibility = View.VISIBLE
            countdownText.text = formatCountdown(state.remainingTimeMs)
        } else {
            countdownText.visibility = View.GONE
        }

        // Cycle count
        if (state.cycleCount > 0) {
            cycleCountText.visibility = View.VISIBLE
            cycleCountText.text = getString(R.string.ohr_auto_cycles_completed, state.cycleCount)
        } else {
            cycleCountText.visibility = View.GONE
        }

        // Log
        logText.text = state.logLines.joinToString("\n")
        logScrollView.post {
            logScrollView.fullScroll(View.FOCUS_DOWN)
        }
    }

    private fun formatCountdown(ms: Long): String {
        val totalSeconds = ms / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
