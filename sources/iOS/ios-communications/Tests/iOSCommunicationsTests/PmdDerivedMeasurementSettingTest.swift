// Copyright © 2026 Polar Electro Oy. All rights reserved.

import XCTest
@testable import iOSCommunications

final class PmdDerivedMeasurementSettingTest: XCTestCase {

    func testDerivedMeasurementSettingsGroupParsing() throws {
        // Arrange
        let bytes = Data([
            0x0C, 0x01, 0x00,
            0x0B, 0x01, 0xE8, 0x03, 0x00, 0x00,
            0x07, 0x03, 0x00, 0x01, 0x02,
            0x08, 0x01, 0x02,
            0x09, 0x01, 0x32, 0x00
        ])

        // Act
        let setting = try PmdSetting(bytes)

        // Assert
        let groupIds = try XCTUnwrap(setting.settings[.derivedMeasurementSettingsGroupId])
        XCTAssertEqual(groupIds.count, 1)
        XCTAssertTrue(groupIds.contains(0))

        let timeWindows = try XCTUnwrap(setting.settings[.derivedMeasurementTimeWindow])
        XCTAssertEqual(timeWindows.count, 1)
        XCTAssertTrue(timeWindows.contains(1000))

        let methods = try XCTUnwrap(setting.settings[.derivedMeasurementMethod])
        XCTAssertEqual(methods.count, 3)
        XCTAssertTrue(methods.contains(0))
        XCTAssertTrue(methods.contains(1))
        XCTAssertTrue(methods.contains(2))

        let sourceTypes = try XCTUnwrap(setting.settings[.sourceMeasurementType])
        XCTAssertEqual(sourceTypes.count, 1)
        XCTAssertTrue(sourceTypes.contains(2))

        let sourceRates = try XCTUnwrap(setting.settings[.sourceMeasurementSampleRate])
        XCTAssertEqual(sourceRates.count, 1)
        XCTAssertTrue(sourceRates.contains(50))
    }

    func testDerivedMeasurementSettingsSerialization() throws {
        // Arrange
        let selected: [PmdSetting.PmdSettingType: UInt32] = [
            .derivedMeasurementSettingsGroupId: 0x22,
            .derivedMeasurementTimeWindow: 1000,
            .derivedMeasurementMethod: 4,
            .sourceMeasurementType: 2,
            .sourceMeasurementSampleRate: 50
        ]

        // Act
        let serialized = PmdSetting(selected).serialize()
        let parsed = try PmdSetting(serialized)

        // Assert
        XCTAssertTrue(try XCTUnwrap(parsed.settings[.derivedMeasurementSettingsGroupId]).contains(0x22))
        XCTAssertTrue(try XCTUnwrap(parsed.settings[.derivedMeasurementTimeWindow]).contains(1000))
        XCTAssertTrue(try XCTUnwrap(parsed.settings[.sourceMeasurementType]).contains(2))
        XCTAssertTrue(try XCTUnwrap(parsed.settings[.sourceMeasurementSampleRate]).contains(50))

        let methods = try XCTUnwrap(parsed.settings[.derivedMeasurementMethod])
        XCTAssertEqual(methods.count, 1)
        XCTAssertTrue(methods.contains(2))
    }

    func testResponseOnlyFieldsNotSerialized() throws {
        // Arrange
        let selected: [PmdSetting.PmdSettingType: UInt32] = [
            .derivedMeasurementSettingsGroupId: 0x22,
            .derivedMeasurementTimeWindow: 1000,
            .derivedMeasurementMethod: 1,
            .sourceMeasurementType: 2,
            .sourceMeasurementSampleRate: 50,
            .factor: UInt32(Float(1.0).bitPattern),
            .sourceMeasurementRange: 8
        ]

        // Act
        let parsed = try PmdSetting(PmdSetting(selected).serialize())

        // Assert
        XCTAssertNil(parsed.settings[.factor])
        XCTAssertNil(parsed.settings[.sourceMeasurementRange])
        XCTAssertNotNil(parsed.settings[.derivedMeasurementSettingsGroupId])
        XCTAssertNotNil(parsed.settings[.derivedMeasurementTimeWindow])
    }

    func testLargeTimeWindowSerialization() throws {
        // Arrange
        let oneDayMs: UInt32 = 86_400_000
        let selected: [PmdSetting.PmdSettingType: UInt32] = [
            .derivedMeasurementSettingsGroupId: 0x01,
            .derivedMeasurementTimeWindow: oneDayMs,
            .derivedMeasurementMethod: 1,
            .sourceMeasurementType: 2,
            .sourceMeasurementSampleRate: 50
        ]

        // Act
        let parsed = try PmdSetting(PmdSetting(selected).serialize())

        // Assert
        XCTAssertTrue(try XCTUnwrap(parsed.settings[.derivedMeasurementTimeWindow]).contains(oneDayMs))
    }
}