//  Copyright 2026 Polar. All rights reserved.

import SwiftUI

private enum EcgConstants {
    static let maxDisplaySamples = 1300
    static let ecgGridLines = 6
    static let p95Percentile: Float = 0.95
    static let minRepAbsMicroV: Float = 450
    static let scalePadFactor: Float = 1.3
    static let snapIntervalMicroV: Float = 100
    static let minRangeMicroV = 600
    static let maxRangeMicroV = 2000
    static let hysteresisDownThreshold: Float = 0.75

    // UI dimensions
    static let leftPadding: CGFloat = 60
    static let graphPadding: CGFloat = 16
    static let headerPadding: CGFloat = 8
    static let ecgLineStrokeWidth: CGFloat = 1.5
    static let gridLineStrokeWidth: CGFloat = 1
    static let verticalInset: CGFloat = 10

    // Text sizes
    static let voltageTextSize: CGFloat = 22
    static let labelTextSize: CGFloat = 11

    // Colors
    static let buttonRed = Color(red: 0.83, green: 0.18, blue: 0.18)
    static let graphBackground = Color.black
    static let ecgLineColor = Color.green
    static let gridColor = Color.gray.opacity(0.3)
    static let textColor = Color.white
}

struct EcgGraphView: View {
    @ObservedObject private var ecgDataHolder = EcgDataHolder.shared
    let onClose: () -> Void

    @State private var lastDisplayRange: (min: Int, max: Int)? = nil

    private var voltageValues: [Int32] {
        ecgDataHolder.ecgState.ecgSamples.map { $0.voltage }
    }

    private var displayRange: (min: Int, max: Int) {
        calculateEcgDisplayRange(values: voltageValues, previous: lastDisplayRange)
    }

    var body: some View {
        ZStack {
            EcgConstants.graphBackground
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                EcgPlotterCanvas(
                    voltageValues: voltageValues,
                    displayMin: displayRange.min,
                    displayMax: displayRange.max
                )
                .padding(EcgConstants.graphPadding)
            }
        }
        .onChange(of: voltageValues.count) { _ in
            lastDisplayRange = calculateEcgDisplayRange(values: voltageValues, previous: lastDisplayRange)
        }
    }

    private var headerView: some View {
        HStack {
            Text("ECG: \(ecgDataHolder.ecgState.currentVoltage) µV")
                .foregroundColor(EcgConstants.textColor)
                .font(.system(size: EcgConstants.voltageTextSize))
            Spacer()
            Button(action: onClose) {
                Text("Close")
                    .foregroundColor(EcgConstants.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(EcgConstants.buttonRed)
                    .cornerRadius(4)
            }
        }
        .padding(EcgConstants.headerPadding)
    }
}

private func calculateEcgDisplayRange(values: [Int32], previous: (min: Int, max: Int)?) -> (min: Int, max: Int) {
    guard !values.isEmpty else { return previous ?? (-1000, 1000) }

    let absValues = values.map { abs(Float($0)) }.sorted()
    let p95Index = Int(Float(absValues.count - 1) * EcgConstants.p95Percentile)
        .clamped(to: 0...(absValues.count - 1))
    let repAbs = max(absValues[p95Index], EcgConstants.minRepAbsMicroV)

    let padded = repAbs * EcgConstants.scalePadFactor
    let snapped = Int(ceil(padded / EcgConstants.snapIntervalMicroV) * EcgConstants.snapIntervalMicroV)
    let clamped = min(max(snapped, EcgConstants.minRangeMicroV), EcgConstants.maxRangeMicroV)

    if let prev = previous {
        let prevMax = abs(prev.1)
        let atMinimum = clamped == EcgConstants.minRangeMicroV
        let keep = !atMinimum && clamped <= prevMax && Float(clamped) >= Float(prevMax) * EcgConstants.hysteresisDownThreshold
        if keep { return prev }
    }
    return (-clamped, clamped)
}

struct EcgPlotterCanvas: View {
    let voltageValues: [Int32]
    let displayMin: Int
    let displayMax: Int

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let leftPadding = EcgConstants.leftPadding
            let graphWidth = width - leftPadding
            let inset = EcgConstants.verticalInset
            let plotHeight = height - inset * 2
            let minV = CGFloat(displayMin)
            let maxV = CGFloat(displayMax)
            let vRange = max(maxV - minV, 1)
            let gridLines = EcgConstants.ecgGridLines

            for i in 0...gridLines {
                let fraction = CGFloat(i) / CGFloat(gridLines)
                let gridValue = minV + fraction * vRange
                let y = inset + (1 - fraction) * plotHeight

                let gridPath = Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                context.stroke(gridPath, with: .color(EcgConstants.gridColor),
                               lineWidth: EcgConstants.gridLineStrokeWidth)

                let label = Text(String(format: "%.0f", gridValue))
                    .font(.system(size: EcgConstants.labelTextSize))
                    .foregroundColor(EcgConstants.textColor)
                context.draw(label, at: CGPoint(x: leftPadding / 2, y: y))
            }

            guard !voltageValues.isEmpty else { return }

            let stepX = graphWidth / CGFloat(max(EcgConstants.maxDisplaySamples - 1, 1))
            var linePath = Path()
            for (index, v) in voltageValues.enumerated() {
                let x = leftPadding + CGFloat(index) * stepX
                let clampedV = CGFloat(min(max(Int(v), displayMin), displayMax))
                let y = inset + (1 - (clampedV - minV) / vRange) * plotHeight
                if index == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(linePath, with: .color(EcgConstants.ecgLineColor),
                           lineWidth: EcgConstants.ecgLineStrokeWidth)

            let lastIndex = voltageValues.count - 1
            let lastV = CGFloat(min(max(Int(voltageValues.last!), displayMin), displayMax))
            let dotX = leftPadding + CGFloat(lastIndex) * stepX
            let dotY = inset + (1 - (lastV - minV) / vRange) * plotHeight
            let dotRect = CGRect(x: dotX - 4, y: dotY - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dotRect), with: .color(EcgConstants.ecgLineColor))
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct EcgGraphView_Previews: PreviewProvider {
    static var previews: some View {
        EcgGraphView(onClose: {})
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
