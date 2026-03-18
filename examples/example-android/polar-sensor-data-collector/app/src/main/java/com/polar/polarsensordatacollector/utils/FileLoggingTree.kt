package com.polar.polarsensordatacollector.utils

import android.content.Context
import android.os.Process
import android.util.Log
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Captures Logcat output for this process and writes it to rotating log files
 * in the app's external files directory (`getExternalFilesDir(null)/logs/`).
 *
 * Usage:
 *   FileLoggingTree.start(applicationContext)   // call once in Application.onCreate()
 *   FileLoggingTree.stop()                      // optional, e.g. in onTerminate()
 */
object FileLoggingTree {

    private const val TAG = "FileLoggingTree"
    private const val MAX_FILE_SIZE_BYTES = 5L * 1024L * 1024L // 5 MB

    @Volatile
    private var logThread: Thread? = null

    @Volatile
    private var logProcess: java.lang.Process? = null

    fun start(context: Context) {
        if (logThread != null) return

        val logsDir = File(context.getExternalFilesDir(null), "logs")
        logsDir.mkdirs()

        logThread = Thread({
            try {
                runLogging(logsDir)
            } catch (e: Exception) {
                Log.e(TAG, "File logging failed", e)
            }
        }, "file-log-writer").apply {
            isDaemon = true
            start()
        }

        Log.i(TAG, "File logging started → ${logsDir.absolutePath}")
    }

    fun stop() {
        logProcess?.destroy()
        logProcess = null
        logThread?.interrupt()
        logThread = null
    }

    /** Returns all log files sorted newest-first. */
    fun getLogFiles(context: Context): List<File> {
        val logsDir = File(context.getExternalFilesDir(null), "logs")
        if (!logsDir.exists()) return emptyList()
        return logsDir.listFiles()
            ?.filter { it.isFile && it.name.startsWith("app_log_") }
            ?.sortedByDescending { it.lastModified() }
            ?: emptyList()
    }

    private fun runLogging(logsDir: File) {
        val pid = Process.myPid().toString()

        // Clear the logcat buffer first so we don't re-dump old entries
        Runtime.getRuntime().exec(arrayOf("logcat", "-c")).waitFor()

        val process = Runtime.getRuntime().exec(
            arrayOf("logcat", "-v", "threadtime", "--pid=$pid")
        )
        logProcess = process

        val reader = BufferedReader(InputStreamReader(process.inputStream))
        var outputStream = newLogFileStream(logsDir)
        var bytesWritten = 0L

        try {
            var line = reader.readLine()
            while (line != null) {
                val bytes = (line + "\n").toByteArray(Charsets.UTF_8)
                outputStream.write(bytes)
                bytesWritten += bytes.size

                if (bytesWritten >= MAX_FILE_SIZE_BYTES) {
                    outputStream.flush()
                    outputStream.close()
                    outputStream = newLogFileStream(logsDir)
                    bytesWritten = 0L
                }

                line = reader.readLine()
            }
        } finally {
            outputStream.flush()
            outputStream.close()
            reader.close()
            process.destroy()
        }
    }

    private fun newLogFileStream(logsDir: File): FileOutputStream {
        val timestamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US).format(Date())
        val file = File(logsDir, "app_log_$timestamp.txt")
        return FileOutputStream(file, true)
    }
}
