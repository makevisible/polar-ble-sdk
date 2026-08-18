/// Copyright © 2022 Polar Electro Oy. All rights reserved.

import Foundation
import SwiftUI
import PolarBleSdk

struct H10ExerciseView: View {

    private struct ShownExcerciseData: Identifiable {
        // Recording interval in seconds.
        let recordingInterval: UInt32
        // HR or RR samples.
        let hrSamples: [UInt32]
        let title: String
        var id: String { return "\(hrSamples)" }
    }

    @EnvironmentObject var bleSdkManager: PolarBleSdkManager
    @State private var shownExcerciseData: ShownExcerciseData? = nil
    @State private var showingShareSheet: Bool = false

    var body: some View {

        VStack {

            Button("List exercises",
                   action: {
                Task {
                    await bleSdkManager.listH10Exercises()
                    if (bleSdkManager.h10ExerciseEntry == nil) {
                        bleSdkManager.generalMessage = Message(text: "No exercises to list in device")
                    } else {
                        bleSdkManager.generalMessage = Message(text: "Exercise found for date: \(bleSdkManager.h10ExerciseEntry?.date.description ?? "unknown")")
                    }
                }
            }
            ).buttonStyle(SecondaryButtonStyle(buttonState: getButtonState()))

            HStack(spacing: 12) {
                Button(bleSdkManager.h10RecordingFeature.isFetchingRecording ? "Reading exercise" : "Read exercise",
                       action: {
                    Task {
                        await bleSdkManager.h10ReadExercise()
                        if bleSdkManager.exerciseData == nil {
                            bleSdkManager.generalMessage = Message(text: "No exercise data available")
                        }
                    }
                })
                .buttonStyle(SecondaryButtonStyle(buttonState: getRecordingReadButtonState()))
                .disabled(bleSdkManager.h10RecordingFeature.isFetchingRecording)
                .overlay {
                    if bleSdkManager.h10RecordingFeature.isFetchingRecording {
                        ProgressView()
                    }
                }
                .sheet(item: $shownExcerciseData) { data in
                    NavigationView {
                        TextViewerView(
                            title: data.title,
                            text: "Interval: \(data.recordingInterval)\n\nSamples:\n" + data.hrSamples.map(String.init).joined(separator: "\n")
                        )
                    }
                }

                if let exerciseData = bleSdkManager.exerciseData {
                    let exerciseText = "Interval: \(exerciseData.interval)\n\nSamples:\n" + exerciseData.samples.map(String.init).joined(separator: "\n")

                    ShareButton {
                        showingShareSheet = true
                    }
                    .sheet(isPresented: $showingShareSheet) {
                        ActivityView(
                            text: exerciseText,
                            filename: "H10_exercise_\(exerciseData.interval).txt"
                        )
                    }

                    ShowButton {
                        shownExcerciseData = ShownExcerciseData(
                            recordingInterval: exerciseData.interval,
                            hrSamples: exerciseData.samples,
                            title: "H10 exercise data"
                        )
                    }
                }
            }

            Button("Remove exercise",
                   action: { bleSdkManager.h10RemoveExercise() }
            ).buttonStyle(SecondaryButtonStyle(buttonState: getButtonState()))

            Button(bleSdkManager.h10RecordingFeature.isEnabled ? "Stop H10 recording" : "Start H10 recording",
                   action: { bleSdkManager.h10RecordingToggle() }
            ).buttonStyle(SecondaryButtonStyle(buttonState: getRecordingButtonState()))
        }
    }

    func getButtonState() -> ButtonState {
        if bleSdkManager.h10RecordingFeature.isSupported {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }

    func getRecordingButtonState() -> ButtonState {
        if bleSdkManager.h10RecordingFeature.isSupported {
            if bleSdkManager.h10RecordingFeature.isEnabled {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        } else {
            return ButtonState.disabled
        }
    }

    func getRecordingStatusButtonState() -> ButtonState {
        if bleSdkManager.h10RecordingFeature.isSupported {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }

    func getRecordingReadButtonState() -> ButtonState {
        if bleSdkManager.h10RecordingFeature.isSupported {
            if(bleSdkManager.h10RecordingFeature.isFetchingRecording) {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        } else {
            return ButtonState.disabled
        }
    }
}

struct H10ExerciseView_Previews: PreviewProvider {
    private static let h10RecordingFeature = H10RecordingFeature(
        isSupported: true,
        isEnabled: true,
        isFetchingRecording: true
    )

    private static let polarBleSdkManager: PolarBleSdkManager = {
        let polarBleSdkManager = PolarBleSdkManager()
        polarBleSdkManager.h10RecordingFeature = h10RecordingFeature
        return polarBleSdkManager
    }()

    static var previews: some View {
        ForEach(["iPhone 7 Plus", "iPad Pro (12.9-inch) (6th generation)"], id: \.self) { deviceName in
            H10ExerciseView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
                .environmentObject(polarBleSdkManager)
        }
    }
}

fileprivate struct ShareButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 28))
        }
    }
}

fileprivate struct ShowButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 28))
        }
    }
}
