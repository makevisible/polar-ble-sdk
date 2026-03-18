package com.polar.polarsensordatacollector.ui.h10exercise

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.google.gson.GsonBuilder
import com.polar.polarsensordatacollector.R
import com.polar.polarsensordatacollector.utils.FileLoggingTree
import com.polar.sdk.api.model.PolarExerciseData
import dagger.hilt.android.AndroidEntryPoint
import java.io.File
import java.util.Locale

private const val TAG = "H10ExerciseFragment"

@AndroidEntryPoint
class H10ExerciseFragment : Fragment() {

    private val viewModel: H10ExerciseViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = ComposeView(requireContext()).apply {
        setContent {
            var statusText by remember { mutableStateOf("") }
            val featureState by viewModel.featureState.collectAsState()
            
            // Automation UI State
            val autoUiState by viewModel.autoUiState.collectAsState()
            
            // Duration pickers state
            var hours by remember { mutableStateOf(3) }
            var minutes by remember { mutableStateOf(0) }

            MaterialTheme {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black),
                    color = Color.Black,
                    elevation = 0.dp
                ) {
                    val context = LocalContext.current
                    
                    val scrollState = rememberScrollState()
                    LaunchedEffect(autoUiState.logLines.size) {
                        scrollState.animateScrollTo(scrollState.maxValue)
                    }

                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp)
                            .verticalScroll(scrollState),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        
                        Text(
                            text = "H10 Manual Controls",
                            color = Color.White,
                            style = MaterialTheme.typography.h6
                        )

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.Gray),
                            modifier = Modifier.fillMaxWidth(),
                            onClick = {
                                viewModel.listExercises(
                                    onResult = { count ->
                                        statusText = if (count > 0) {
                                            context.getString(R.string.exercises_found)
                                        } else {
                                            context.getString(R.string.no_exercise_found)
                                        }
                                    },
                                    onError = {
                                        statusText = context.getString(R.string.no_exercise_found)
                                    }
                                )
                            }
                        ) {
                            Text(context.getString(R.string.list_exercises))
                        }

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.Gray),
                            modifier = Modifier.fillMaxWidth(),
                            onClick = {
                                viewModel.readFirstExercise(
                                    onExercise = { exercise ->
                                        shareExerciseData(context, exercise)
                                    },
                                    onError = {
                                        statusText = context.getString(R.string.no_exercise_found)
                                    }
                                )
                            }
                        ) {
                            Text(context.getString(R.string.read_exercise))
                        }

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.Gray),
                            modifier = Modifier.fillMaxWidth(),
                            onClick = {
                                viewModel.removeFirstExercise(
                                    onComplete = {
                                        statusText = context.getString(R.string.exercise_removed_successfully)
                                    },
                                    onError = {
                                        statusText = context.getString(R.string.no_exercise_to_remove)
                                    }
                                )
                            }
                        ) {
                            Text(context.getString(R.string.remove_exercise))
                        }

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.Gray),
                            modifier = Modifier.fillMaxWidth(),
                            onClick = {
                                viewModel.toggleRecording()
                            }
                        ) {
                            Text(
                                if (featureState.isEnabled)
                                    context.getString(R.string.stop_h10_recording)
                                else
                                    context.getString(R.string.start_h10_recording)
                            )
                        }

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.DarkGray),
                            modifier = Modifier.fillMaxWidth(),
                            onClick = { shareLogFiles(context) }
                        ) {
                            Text(context.getString(R.string.share_logs_via))
                        }

                        if (statusText.isNotEmpty()) {
                            Text(
                                text = statusText,
                                color = Color.LightGray
                            )
                        }

                        Divider(color = Color.DarkGray, modifier = Modifier.padding(vertical = 16.dp))

                        // --- Automation UI ---
                        Text(
                            text = "H10 Automation",
                            color = Color.White,
                            style = MaterialTheme.typography.h6
                        )

                        // Duration Picker
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Wait:", color = Color.White)
                            OutlinedTextField(
                                value = hours.toString(),
                                onValueChange = { hours = it.toIntOrNull() ?: 0 },
                                label = { Text("Hours", color = Color.LightGray) },
                                colors = TextFieldDefaults.outlinedTextFieldColors(textColor = Color.White),
                                modifier = Modifier.weight(1f),
                                enabled = !autoUiState.isRunning
                            )
                            OutlinedTextField(
                                value = minutes.toString(),
                                onValueChange = { minutes = it.toIntOrNull() ?: 0 },
                                label = { Text("Mins", color = Color.LightGray) },
                                colors = TextFieldDefaults.outlinedTextFieldColors(textColor = Color.White),
                                modifier = Modifier.weight(1f),
                                enabled = !autoUiState.isRunning
                            )
                        }

                        // Auto Buttons
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Button(
                                modifier = Modifier.weight(1f),
                                onClick = {
                                    if (autoUiState.isRunning) {
                                        viewModel.stopAutomation()
                                    } else {
                                        viewModel.startAutomation(hours, minutes)
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(
                                    backgroundColor = if (autoUiState.isRunning) Color.Red else Color.Green
                                )
                            ) {
                                Text(if (autoUiState.isRunning) "Stop" else "Start", color = Color.White)
                            }

                            Button(
                                modifier = Modifier.weight(1f),
                                onClick = { viewModel.stopAndFetch() },
                                enabled = autoUiState.isRunning
                            ) {
                                Text("Stop & Fetch")
                            }

                            Button(
                                modifier = Modifier.weight(1f),
                                onClick = { viewModel.skipWait() },
                                enabled = autoUiState.phase == H10AutomationPhase.WAITING
                            ) {
                                Text("Skip Wait")
                            }
                        }

                        Button(
                            colors = ButtonDefaults.buttonColors(backgroundColor = Color.DarkGray),
                            modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                            onClick = { shareAutoRecordedData(context) }
                        ) {
                            Text("Share Auto-Recorded Data")
                        }

                        // Status and Countdowns
                        val phaseText = when (autoUiState.phase) {
                            H10AutomationPhase.STARTING_RECORDING -> "Starting Recording..."
                            H10AutomationPhase.WAITING -> "Waiting in Background..."
                            H10AutomationPhase.STOPPING_RECORDING -> "Stopping Recording..."
                            H10AutomationPhase.FETCHING -> "Fetching Exercises..."
                            H10AutomationPhase.CLEANING -> "Cleaning Device..."
                            H10AutomationPhase.SAVING -> "Saving Locally..."
                            H10AutomationPhase.CYCLE_COMPLETE -> "Cycle Complete!"
                            H10AutomationPhase.ERROR -> "Error!"
                            H10AutomationPhase.IDLE -> "Idle"
                        }

                        Text(
                            text = phaseText,
                            style = MaterialTheme.typography.body1,
                            color = Color.White
                        )

                        if (autoUiState.remainingTimeMs > 0) {
                            val totalSeconds = autoUiState.remainingTimeMs / 1000
                            val h = totalSeconds / 3600
                            val m = (totalSeconds % 3600) / 60
                            val s = totalSeconds % 60
                            val countdown = String.format(Locale.US, "%02d:%02d:%02d", h, m, s)
                            Text(
                                text = countdown,
                                style = MaterialTheme.typography.h4,
                                color = Color.White
                            )
                        }

                        if (autoUiState.cycleCount > 0) {
                            Text(
                                text = "Cycles completed: ${autoUiState.cycleCount}",
                                color = Color.LightGray
                            )
                        }

                        // Log Console
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 200.dp),
                            color = Color.DarkGray
                        ) {
                            Column(modifier = Modifier.padding(8.dp)) {
                                Text(
                                    text = autoUiState.logLines.joinToString("\n"),
                                    fontFamily = FontFamily.Monospace,
                                    fontSize = 12.sp,
                                    color = Color.Green
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private fun shareExerciseData(context: android.content.Context, exerciseData: PolarExerciseData) {
        try {
            val gson = GsonBuilder().setPrettyPrinting().create()
            val json = gson.toJson(
                mapOf(
                    "recordingInterval" to exerciseData.recordingInterval,
                    "hrSamples" to exerciseData.hrSamples
                )
            )

            val file = File(context.filesDir, "exercise.json")
            file.writeText(json)

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/json"
                putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.exported_exercise_data))
                putExtra(Intent.EXTRA_TEXT, context.getString(R.string.attached_is_your_exercise_data_in_json_format))
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            context.startActivity(
                Intent.createChooser(
                    intent,
                    context.getString(R.string.share_exercise_data)
                )
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to share exercise: $e", e)
            Toast.makeText(
                context,
                context.getString(R.string.failed_to_share, e.message),
                Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun shareLogFiles(context: android.content.Context) {
        try {
            val logFiles = FileLoggingTree.getLogFiles(context)
            if (logFiles.isEmpty()) {
                Toast.makeText(context, "No log files found", Toast.LENGTH_SHORT).show()
                return
            }

            // Zip all log files into a single archive
            val zipFile = File(context.cacheDir, "psdc_logs.zip")
            java.util.zip.ZipOutputStream(zipFile.outputStream()).use { zos ->
                for (file in logFiles) {
                    zos.putNextEntry(java.util.zip.ZipEntry(file.name))
                    file.inputStream().use { it.copyTo(zos) }
                    zos.closeEntry()
                }
            }

            val zipUri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", zipFile)

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/zip"
                putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.log_share_subject))
                putExtra(Intent.EXTRA_TEXT, context.getString(R.string.log_share_text))
                putExtra(Intent.EXTRA_STREAM, zipUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            context.startActivity(
                Intent.createChooser(intent, context.getString(R.string.share_logs_via))
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to share logs: $e", e)
            Toast.makeText(
                context,
                context.getString(R.string.failed_to_share, e.message),
                Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun shareAutoRecordedData(context: android.content.Context) {
        try {
            val baseDir = File(context.getExternalFilesDir(null), "polar_h10_logs")
            if (!baseDir.exists()) {
                Toast.makeText(context, "No automated records found", Toast.LENGTH_SHORT).show()
                return
            }

            // Find all JSON files and text logs recursively
            val filesToShare = baseDir.walkTopDown().filter { 
                it.isFile && (it.extension == "json" || it.extension == "txt") 
            }.toList()
            
            if (filesToShare.isEmpty()) {
                Toast.makeText(context, "No automated records found", Toast.LENGTH_SHORT).show()
                return
            }

            // Zip all files into a single archive
            val zipFile = File(context.cacheDir, "h10_automated_records.zip")
            java.util.zip.ZipOutputStream(zipFile.outputStream()).use { zos ->
                for (file in filesToShare) {
                    // Use relative path within the zip
                    val relativePath = file.relativeTo(baseDir).path
                    zos.putNextEntry(java.util.zip.ZipEntry(relativePath))
                    file.inputStream().use { it.copyTo(zos) }
                    zos.closeEntry()
                }
            }

            val zipUri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", zipFile)

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/zip"
                putExtra(Intent.EXTRA_SUBJECT, "H10 Automated Records")
                putExtra(Intent.EXTRA_TEXT, "Attached are the H10 automated records and logs.")
                putExtra(Intent.EXTRA_STREAM, zipUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            context.startActivity(
                Intent.createChooser(intent, "Share records via")
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to share records: $e", e)
            Toast.makeText(
                context,
                "Failed to share: ${e.message}",
                Toast.LENGTH_LONG
            ).show()
        }
    }
}