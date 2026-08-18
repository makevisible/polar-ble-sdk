// Copyright © 2026 Polar Electro Oy. All rights reserved.

import Foundation

/// Derived measurement methods supported by the device (methods 0–9).
///
/// Any non-empty subset of the methods supported by a group may be requested simultaneously.
/// Each active method appends its output values to the derived sample in ascending id order.
///
/// Methods 0–4 are applied component-wise (e.g. X, Y, Z for ACC).
/// Methods 5–9 reduce the D-dimensional source vector to a single unsigned scalar.
public enum PolarDerivedMeasurementMethod: Int, CaseIterable, Sendable {

    /// Method 0 — last source sample within the time window (downsampled).
    case downsample = 0

    /// Method 1 — component-wise minimum of source samples within the time window.
    case min = 1

    /// Method 2 — component-wise maximum of source samples within the time window.
    case max = 2

    /// Method 3 — component-wise average of source samples within the time window.
    case avg = 3

    /// Method 4 — component-wise standard deviation (unsigned-promoted type).
    /// e.g. int16 source component → uint16 std output.
    case std = 4

    /// Method 5 — Euclidean norm (magnitude) of downsampled source vector. D→1 scalar, unsigned-promoted.
    case norm = 5

    /// Method 6 — minimum Euclidean norm across source samples within the time window. D→1 scalar.
    case minOfNorms = 6

    /// Method 7 — maximum Euclidean norm across source samples within the time window. D→1 scalar.
    case maxOfNorms = 7

    /// Method 8 — standard deviation of Euclidean norms within the time window. D→1 scalar.
    case stdOfNorms = 8

    /// Method 9 — Euclidean norm of component-wise standard deviations. D→1 scalar.
    case normOfStds = 9

    /// CSV label for this method.
    public var csvLabel: String {
        switch self {
        case .downsample: return "DS"
        case .min: return "MIN"
        case .max: return "MAX"
        case .avg: return "AVG"
        case .std: return "STD"
        case .norm: return "NORM"
        case .minOfNorms: return "MIN_OF_NORMS"
        case .maxOfNorms: return "MAX_OF_NORMS"
        case .stdOfNorms: return "STD_OF_NORMS"
        case .normOfStds: return "NORM_OF_STDS"
        }
    }

    /// Returns the `PolarDerivedMeasurementMethod` whose wire id matches, or nil if unknown.
    public static func fromId(_ id: Int) -> PolarDerivedMeasurementMethod? {
        return allCases.first { $0.rawValue == id }
    }
}

/// Available settings for one Derived Measurement Settings Group returned by the device.
///
/// Obtain an instance by calling `PolarDerivedMeasurementApi.requestDerivedMeasurementSettingsGroup`.
///
/// - Parameter groupId: the Derived Measurement Settings Group ID advertised by the device
/// - Parameter sourceTypes: the source measurement data types supported by this group
/// - Parameter sourceSampleRates: the source measurement sample rates (Hz) available in this group
/// - Parameter timeWindowOptions: the derived measurement time window durations (ms) available in this group.
///   The time window defines the output cadence: e.g. 1000 ms → 1 Hz derived output.
/// - Parameter supportedMethods: the derived measurement methods supported in this group.
///   Any non-empty subset of `supportedMethods` may be selected when starting a recording.
public struct PolarDerivedMeasurementSettingsGroup: Sendable {
    public let groupId: Int
    public let sourceTypes: Set<PolarDeviceDataType>
    public let sourceSampleRates: Set<Int>
    public let timeWindowOptions: Set<Int>
    public let supportedMethods: Set<PolarDerivedMeasurementMethod>

    public init(groupId: Int,
                sourceTypes: Set<PolarDeviceDataType>,
                sourceSampleRates: Set<Int>,
                timeWindowOptions: Set<Int>,
                supportedMethods: Set<PolarDerivedMeasurementMethod>) {
        self.groupId = groupId
        self.sourceTypes = sourceTypes
        self.sourceSampleRates = sourceSampleRates
        self.timeWindowOptions = timeWindowOptions
        self.supportedMethods = supportedMethods
    }
}

/// Selected settings for starting a derived offline recording.
///
/// Any non-empty subset of the supported methods may be requested simultaneously.
/// Each selected method appends its result values to every derived sample.
///
/// - Parameter groupId: Derived Measurement Settings Group ID obtained from the device
/// - Parameter sourceMeasurementType: source sensor data type to derive from (e.g. ACC)
/// - Parameter sourceSampleRate: source sensor sample rate in Hz (e.g. 50)
/// - Parameter timeWindowMs: output cadence in milliseconds (e.g. 1000 for 1 Hz)
/// - Parameter selectedMethods: non-empty set of methods to apply; results are concatenated per sample
public struct PolarDerivedMeasurementSettings: Sendable {
    public let groupId: Int
    public let sourceMeasurementType: PolarDeviceDataType
    public let sourceSampleRate: Int
    public let timeWindowMs: Int
    public let selectedMethods: Set<PolarDerivedMeasurementMethod>

    public init(groupId: Int,
                sourceMeasurementType: PolarDeviceDataType,
                sourceSampleRate: Int,
                timeWindowMs: Int,
                selectedMethods: Set<PolarDerivedMeasurementMethod>) {
        precondition(sourceSampleRate > 0, "sourceSampleRate must be positive")
        precondition(timeWindowMs > 0, "timeWindowMs must be positive")
        precondition(!selectedMethods.isEmpty, "selectedMethods must not be empty")
        self.groupId = groupId
        self.sourceMeasurementType = sourceMeasurementType
        self.sourceSampleRate = sourceSampleRate
        self.timeWindowMs = timeWindowMs
        self.selectedMethods = selectedMethods
    }
}

/// One derived-measurement sample produced per time window (e.g. 1 sample/s with 1 000 ms window).
///
/// `methodValues` maps each active `PolarDerivedMeasurementMethod` to its output values:
/// - Component methods (DOWNSAMPLE, MIN, MAX, AVG, STD for a 3-axis source) → `[x, y, z]`
/// - Scalar methods (NORM, MIN_OF_NORMS, MAX_OF_NORMS, STD_OF_NORMS, NORM_OF_STDS) → `[v]`
///
/// - Parameter timeStamp: sample timestamp in nanoseconds, corresponds to end of the time window
/// - Parameter activeMethods: the set of methods active for this recording
/// - Parameter methodValues: output values per active method; absent key means method was not active
public struct PolarDerivedSample: Sendable {
    public let timeStamp: UInt64
    public let activeMethods: Set<PolarDerivedMeasurementMethod>
    public let methodValues: [PolarDerivedMeasurementMethod: [Int32]]

    public init(timeStamp: UInt64,
                activeMethods: Set<PolarDerivedMeasurementMethod>,
                methodValues: [PolarDerivedMeasurementMethod: [Int32]]) {
        self.timeStamp = timeStamp
        self.activeMethods = activeMethods
        self.methodValues = methodValues
    }
}

/// Container for a list of derived ACC samples.
public struct PolarDerivedAccData: Sendable {
    public let samples: [PolarDerivedSample]

    public init(samples: [PolarDerivedSample]) {
        self.samples = samples
    }
}
