package com.polar.polarsensordatacollector.ui.graph

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

const val ECG_BUFFER_SIZE = 3000

object EcgDataHolder {

    data class EcgSample(val voltage: Int)

    data class EcgState(
        val ecgSamples: List<EcgSample> = emptyList(),
        val currentVoltage: Int = 0
    )

    private val _ecgState = MutableStateFlow(EcgState())
    val ecgState: StateFlow<EcgState> = _ecgState.asStateFlow()

    private val ecgSamplesList = ArrayDeque<EcgSample>(ECG_BUFFER_SIZE + 1)

    fun updateEcg(voltage: Int) {
        ecgSamplesList.addLast(EcgSample(voltage))
        if (ecgSamplesList.size > ECG_BUFFER_SIZE) ecgSamplesList.removeFirst()
        _ecgState.value = EcgState(
            ecgSamples = ecgSamplesList.toList(),
            currentVoltage = voltage
        )
    }

    fun clear() {
        ecgSamplesList.clear()
        _ecgState.value = EcgState()
    }
}
