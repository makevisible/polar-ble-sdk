///  Copyright © 2024 Polar. All rights reserved.

import Foundation

/// Steps count for given date.
public struct PolarStepsData: Codable {
    public let date: Date
    public let steps: Int

    public init(date: Date, steps: Int) {
        self.date = date
        self.steps = steps
    }
}
