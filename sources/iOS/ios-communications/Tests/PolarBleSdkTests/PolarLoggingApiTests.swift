// Copyright © 2026 Polar Electro Oy. All rights reserved.

import XCTest
@testable import PolarBleSdk

class PolarLoggingApiTests: XCTestCase {

    var mockClient: MockBlePsFtpClient!
    var mockSession: MockBleDeviceSession!
    var api: PolarBleApiImplWithMockSession!
    let deviceId = "12345678"

    override func setUpWithError() throws {
        BlePolarDeviceCapabilitiesUtility.resetAndInitializeForTesting(
            deviceFileSystemTypes: [:],
            defaultFileSystemType: .polarFileSystemV2,
            defaultRecordingSupported: false
        )
        mockClient = MockBlePsFtpClient(gattServiceTransmitter: MockPolarGattServiceTransmitter())
        mockSession = MockBleDeviceSession(mockFtpClient: mockClient)
        api = PolarBleApiImplWithMockSession(mockDeviceSession: mockSession)
    }

    override func tearDownWithError() throws {
        mockClient = nil
        mockSession = nil
        api = nil
    }

    // MARK: - exportDeviceLogs

    func testExportDeviceLogs_allStaticFilesPresent() async throws {
        // Arrange: ERRORLOG.BPB, ERRORLO2.BPB, SYSLOG.TXT all return data; TRC1.BIN is missing
        let errorLogData  = Data("error log content".utf8)
        let errorLo2Data  = Data("secondary error log".utf8)
        let syslogData    = Data("system log content".utf8)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            switch op.path {
            case "/ERRORLOG.BPB":  return errorLogData
            case "/ERRORLO2.BPB":  return errorLo2Data
            case "/SYSLOG.TXT":    return syslogData
            default:
                throw BlePsFtpException.responseError(errorCode: 103) // not found
            }
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert
        XCTAssertEqual(logs.count, 3)
        XCTAssertEqual(logs[0].path, "/ERRORLOG.BPB")
        XCTAssertEqual(logs[0].data, errorLogData)
        XCTAssertEqual(logs[1].path, "/ERRORLO2.BPB")
        XCTAssertEqual(logs[1].data, errorLo2Data)
        XCTAssertEqual(logs[2].path, "/SYSLOG.TXT")
        XCTAssertEqual(logs[2].data, syslogData)
    }

    func testExportDeviceLogs_telemetryTracesIncluded() async throws {
        // Arrange: no static files; TRC1.BIN and TRC2.BIN present, TRC3.BIN missing
        let trc1Data = Data("trc1".utf8)
        let trc2Data = Data("trc2".utf8)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            switch op.path {
            case "/TRC1.BIN": return trc1Data
            case "/TRC2.BIN": return trc2Data
            default:
                throw BlePsFtpException.responseError(errorCode: 103)
            }
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert
        XCTAssertEqual(logs.count, 2)
        XCTAssertEqual(logs[0].path, "/TRC1.BIN")
        XCTAssertEqual(logs[0].data, trc1Data)
        XCTAssertEqual(logs[1].path, "/TRC2.BIN")
        XCTAssertEqual(logs[1].data, trc2Data)
    }

    func testExportDeviceLogs_debugTracesIncluded() async throws {
        // Arrange: no static/TRC files; DBGTRC1.BIN present, DBGTRC2.BIN missing
        let dbgTrc1Data = Data("dbgtrc1".utf8)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            switch op.path {
            case "/DBGTRC1.BIN": return dbgTrc1Data
            default:
                throw BlePsFtpException.responseError(errorCode: 103)
            }
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].path, "/DBGTRC1.BIN")
        XCTAssertEqual(logs[0].data, dbgTrc1Data)
    }

    func testExportDeviceLogs_allFilesPresent_correctOrder() async throws {
        // Arrange: all static files + TRC1 + DBGTRC1
        let paths: [(String, Data)] = [
            ("/ERRORLOG.BPB",  Data("errorlog".utf8)),
            ("/ERRORLO2.BPB",  Data("errorlo2".utf8)),
            ("/SYSLOG.TXT",    Data("syslog".utf8)),
            ("/TRC1.BIN",      Data("trc1".utf8)),
            ("/DBGTRC1.BIN",   Data("dbgtrc1".utf8)),
        ]
        let pathMap = Dictionary(uniqueKeysWithValues: paths)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            if let data = pathMap[op.path] { return data }
            throw BlePsFtpException.responseError(errorCode: 103)
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert
        XCTAssertEqual(logs.map(\.path), paths.map(\.0))
    }

    func testExportDeviceLogs_noFilesPresent_returnsEmpty() async throws {
        // Arrange: every request returns file-not-found
        mockClient.requestReturnValue = .failure(BlePsFtpException.responseError(errorCode: 103))

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert
        XCTAssertTrue(logs.isEmpty)
    }

    func testExportDeviceLogs_nonFatalErrorSkipsFile() async throws {
        // Arrange: ERRORLOG.BPB returns a non-fatal error; SYSLOG.TXT succeeds
        let syslogData = Data("syslog".utf8)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            switch op.path {
            case "/ERRORLOG.BPB":
                throw BlePsFtpException.responseError(errorCode: 500) // some other error
            case "/SYSLOG.TXT":
                return syslogData
            default:
                throw BlePsFtpException.responseError(errorCode: 103)
            }
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert: ERRORLOG.BPB skipped, SYSLOG.TXT included
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].path, "/SYSLOG.TXT")
    }

    func testExportDeviceLogs_trcSequenceStopsAtFirstMissing() async throws {
        // Arrange: TRC1 and TRC2 present, TRC3 missing — TRC4 should never be fetched
        var fetchedPaths: [String] = []
        let trcData = Data("trc".utf8)

        mockClient.requestReturnValueClosure = { header in
            let op = try Protocol_PbPFtpOperation(serializedBytes: header)
            fetchedPaths.append(op.path)
            switch op.path {
            case "/TRC1.BIN", "/TRC2.BIN": return trcData
            default: throw BlePsFtpException.responseError(errorCode: 103)
            }
        }

        // Act
        let logs = try await api.exportDeviceLogs(deviceId)

        // Assert: TRC4+ were never requested
        XCTAssertEqual(logs.filter { $0.path.hasPrefix("/TRC") }.count, 2)
        XCTAssertFalse(fetchedPaths.contains("/TRC4.BIN"))
    }
}
