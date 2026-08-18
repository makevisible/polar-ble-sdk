package com.polar.polarsensordatacollector.ui.graph

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.Button
import androidx.compose.material.ButtonDefaults
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.polar.polarsensordatacollector.R
import kotlinx.coroutines.flow.collectLatest
import java.util.Locale
import kotlin.math.abs
import kotlin.math.ceil

// UI dimensions (dp)
private const val LEFT_PADDING_DP = 50
private const val GRAPH_PADDING_DP = 16
private const val HEADER_PADDING_DP = 8
private const val ECG_LINE_STROKE_WIDTH_DP = 1
private const val ECG_POINT_RADIUS_DP = 4
private const val GRID_LINE_STROKE_WIDTH_DP = 1
private const val Y_LABEL_X_OFFSET_DP = 10
private const val Y_LABEL_Y_OFFSET_DP = 5
private const val ECG_GRID_LINES = 6

// Text sizes (sp)
private const val LABEL_TEXT_SIZE_SP = 12
private const val VALUE_TEXT_SIZE_SP = 18

// Colors
private val BUTTON_RED = Color(0xFFD32F2F)
private val GRAPH_BACKGROUND = Color.Black
private val ECG_LINE_COLOR = Color.Green
private val GRID_COLOR = Color.Gray.copy(alpha = 0.3f)
private val TEXT_COLOR = Color.White

@Composable
fun EcgGraphView(onClose: () -> Unit) {
    var samples by remember { mutableStateOf(emptyList<EcgDataHolder.EcgSample>()) }
    var lastEcgRange by remember { mutableStateOf<Pair<Float, Float>?>(null) }

    LaunchedEffect(Unit) {
        EcgDataHolder.ecgState.collectLatest { state ->
            samples = state.ecgSamples
        }
    }

    val voltageValues = samples.map { it.voltage.toFloat() }
    val ecgRange = calculateEcgRange(voltageValues, lastEcgRange)
    lastEcgRange = ecgRange
    val (displayMin, displayMax) = ecgRange

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(GRAPH_BACKGROUND),
        contentAlignment = Alignment.Center
    ) {
        val width = maxWidth
        val height = maxHeight

        Box(
            modifier = Modifier
                .requiredSize(
                    width = height,
                    height = width
                )
                .rotate(90f)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(HEADER_PADDING_DP.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = stringResource(
                            R.string.ecg_value,
                            samples.lastOrNull()?.voltage?.toString() ?: "--"
                        ),
                        color = TEXT_COLOR,
                        fontSize = VALUE_TEXT_SIZE_SP.sp
                    )

                    Button(
                        onClick = onClose,
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = BUTTON_RED,
                            contentColor = TEXT_COLOR
                        )
                    ) {
                        Text(stringResource(R.string.close))
                    }
                }

                EcgPlotterCanvas(
                    voltageValues = voltageValues,
                    displayMin = displayMin,
                    displayMax = displayMax,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(GRAPH_PADDING_DP.dp)
                )
            }
        }
    }
}

private fun calculateEcgRange(values: List<Float>, previous: Pair<Float, Float>?): Pair<Float, Float> {
    if (values.isEmpty()) return previous ?: (-1000f to 1000f)

    val sorted = values.map { abs(it) }.sorted()
    val p95Index = ((sorted.size - 1) * 0.95f).toInt().coerceIn(0, sorted.lastIndex)
    val repAbs = sorted[p95Index].coerceAtLeast(500f)

    val padded = repAbs * 1.3f
    val snapped = (ceil(padded / 100f) * 100f).coerceIn(1000f, 2000f)

    val newRange = -snapped to snapped

    return if (previous != null) {
        val prevMax = abs(previous.second)
        when {
            snapped > prevMax         -> newRange
            snapped < prevMax * 0.75f -> newRange
            else                      -> previous
        }
    } else {
        newRange
    }
}

@Composable
fun EcgPlotterCanvas(
    voltageValues: List<Float>,
    displayMin: Float,
    displayMax: Float,
    modifier: Modifier = Modifier
) {
    val range = (displayMax - displayMin).coerceAtLeast(1f)

    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height
        val leftPadding = LEFT_PADDING_DP.dp.toPx()
        val graphWidth = width - leftPadding

        repeat(ECG_GRID_LINES + 1) { i ->
            val value = displayMin + i * (range / ECG_GRID_LINES)
            val y = height - ((value - displayMin) / range * height)

            drawLine(
                color = GRID_COLOR,
                start = Offset(leftPadding, y),
                end = Offset(width, y),
                strokeWidth = GRID_LINE_STROKE_WIDTH_DP.dp.toPx()
            )

            drawContext.canvas.nativeCanvas.drawText(
                String.format(Locale.US, "%.0f", value),
                Y_LABEL_X_OFFSET_DP.dp.toPx(),
                y + Y_LABEL_Y_OFFSET_DP.dp.toPx(),
                android.graphics.Paint().apply {
                    color = android.graphics.Color.WHITE
                    textSize = LABEL_TEXT_SIZE_SP.sp.toPx()
                }
            )
        }

        if (voltageValues.isEmpty()) return@Canvas

        val stepX = graphWidth / (ECG_BUFFER_SIZE - 1).coerceAtLeast(1)

        if (voltageValues.size > 1) {
            val path = Path()
            voltageValues.forEachIndexed { index, v ->
                val x = leftPadding + index * stepX
                val y = height - ((v - displayMin) / range * height)
                if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }
            drawPath(
                path = path,
                color = ECG_LINE_COLOR,
                style = Stroke(width = ECG_LINE_STROKE_WIDTH_DP.dp.toPx())
            )
        }

        if (voltageValues.isNotEmpty()) {
            val lastIndex = voltageValues.lastIndex
            val lastV = voltageValues.last()
            val x = leftPadding + lastIndex * stepX
            val y = height - ((lastV - displayMin) / range * height)
            drawCircle(
                color = ECG_LINE_COLOR,
                radius = ECG_POINT_RADIUS_DP.dp.toPx(),
                center = Offset(x, y)
            )
        }
    }
}
