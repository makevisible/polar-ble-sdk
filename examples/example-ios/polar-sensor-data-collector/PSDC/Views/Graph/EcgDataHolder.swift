//  Copyright © 2026 Polar. All rights reserved.

import Foundation

struct EcgSamplePoint {
    let voltage: Int32
}

struct EcgState {
    var ecgSamples: [EcgSamplePoint] = []
    var currentVoltage: Int32 = 0
}

@MainActor
class EcgDataHolder: ObservableObject {
    static let shared = EcgDataHolder()

    private static let maxEcgSamples = 1300

    @Published private(set) var ecgState = EcgState()

    private var ecgSamplesList: [EcgSamplePoint] = []

    private init() {}

    func updateEcg(voltage: Int32) {
        let sample = EcgSamplePoint(voltage: voltage)
        ecgSamplesList.append(sample)

        if ecgSamplesList.count > Self.maxEcgSamples {
            ecgSamplesList.removeFirst(ecgSamplesList.count - Self.maxEcgSamples)
        }

        ecgState = EcgState(
            ecgSamples: ecgSamplesList,
            currentVoltage: voltage
        )
    }

    func clear() {
        ecgSamplesList.removeAll()
        ecgState = EcgState()
    }
}

