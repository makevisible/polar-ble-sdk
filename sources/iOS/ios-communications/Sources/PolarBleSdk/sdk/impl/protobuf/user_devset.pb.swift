// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: user_devset.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// UDEVSET.BPB=PbUserDeviceSettings

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Data_PbUserDeviceGeneralSettings: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Device location on user
  var deviceLocation: PbDeviceLocation {
    get {return _deviceLocation ?? .deviceLocationUndefined}
    set {_deviceLocation = newValue}
  }
  /// Returns true if `deviceLocation` has been explicitly set.
  var hasDeviceLocation: Bool {return self._deviceLocation != nil}
  /// Clears the value of `deviceLocation`. Subsequent reads from it will return its default value.
  mutating func clearDeviceLocation() {self._deviceLocation = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _deviceLocation: PbDeviceLocation? = nil
}

struct Data_PbUserDeviceSettings: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var generalSettings: Data_PbUserDeviceGeneralSettings {
    get {return _generalSettings ?? Data_PbUserDeviceGeneralSettings()}
    set {_generalSettings = newValue}
  }
  /// Returns true if `generalSettings` has been explicitly set.
  var hasGeneralSettings: Bool {return self._generalSettings != nil}
  /// Clears the value of `generalSettings`. Subsequent reads from it will return its default value.
  mutating func clearGeneralSettings() {self._generalSettings = nil}

  var lastModified: PbSystemDateTime {
    get {return _lastModified ?? PbSystemDateTime()}
    set {_lastModified = newValue}
  }
  /// Returns true if `lastModified` has been explicitly set.
  var hasLastModified: Bool {return self._lastModified != nil}
  /// Clears the value of `lastModified`. Subsequent reads from it will return its default value.
  mutating func clearLastModified() {self._lastModified = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _generalSettings: Data_PbUserDeviceGeneralSettings? = nil
  fileprivate var _lastModified: PbSystemDateTime? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "data"

extension Data_PbUserDeviceGeneralSettings: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".PbUserDeviceGeneralSettings"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    15: .standard(proto: "device_location"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 15: try { try decoder.decodeSingularEnumField(value: &self._deviceLocation) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._deviceLocation {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 15)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Data_PbUserDeviceGeneralSettings, rhs: Data_PbUserDeviceGeneralSettings) -> Bool {
    if lhs._deviceLocation != rhs._deviceLocation {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Data_PbUserDeviceSettings: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".PbUserDeviceSettings"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "general_settings"),
    101: .standard(proto: "last_modified"),
  ]

  public var isInitialized: Bool {
    if self._generalSettings == nil {return false}
    if self._lastModified == nil {return false}
    if let v = self._lastModified, !v.isInitialized {return false}
    return true
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._generalSettings) }()
      case 101: try { try decoder.decodeSingularMessageField(value: &self._lastModified) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._generalSettings {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._lastModified {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 101)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Data_PbUserDeviceSettings, rhs: Data_PbUserDeviceSettings) -> Bool {
    if lhs._generalSettings != rhs._generalSettings {return false}
    if lhs._lastModified != rhs._lastModified {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
