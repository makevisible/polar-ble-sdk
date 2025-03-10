// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: device.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// DEVICE.BPB=PbDeviceInfo

import Foundation
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

struct Data_PbDeviceInfo {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var bootloaderVersion: PbVersion {
    get {return _storage._bootloaderVersion ?? PbVersion()}
    set {_uniqueStorage()._bootloaderVersion = newValue}
  }
  /// Returns true if `bootloaderVersion` has been explicitly set.
  var hasBootloaderVersion: Bool {return _storage._bootloaderVersion != nil}
  /// Clears the value of `bootloaderVersion`. Subsequent reads from it will return its default value.
  mutating func clearBootloaderVersion() {_uniqueStorage()._bootloaderVersion = nil}

  var platformVersion: PbVersion {
    get {return _storage._platformVersion ?? PbVersion()}
    set {_uniqueStorage()._platformVersion = newValue}
  }
  /// Returns true if `platformVersion` has been explicitly set.
  var hasPlatformVersion: Bool {return _storage._platformVersion != nil}
  /// Clears the value of `platformVersion`. Subsequent reads from it will return its default value.
  mutating func clearPlatformVersion() {_uniqueStorage()._platformVersion = nil}

  ///
  /// Note: this version also identifies the version of bitmaps, fonts, language files etc.
  var deviceVersion: PbVersion {
    get {return _storage._deviceVersion ?? PbVersion()}
    set {_uniqueStorage()._deviceVersion = newValue}
  }
  /// Returns true if `deviceVersion` has been explicitly set.
  var hasDeviceVersion: Bool {return _storage._deviceVersion != nil}
  /// Clears the value of `deviceVersion`. Subsequent reads from it will return its default value.
  mutating func clearDeviceVersion() {_uniqueStorage()._deviceVersion = nil}

  /// Subversion revision number, from which the device software is compiled from
  var svnRev: UInt32 {
    get {return _storage._svnRev ?? 0}
    set {_uniqueStorage()._svnRev = newValue}
  }
  /// Returns true if `svnRev` has been explicitly set.
  var hasSvnRev: Bool {return _storage._svnRev != nil}
  /// Clears the value of `svnRev`. Subsequent reads from it will return its default value.
  mutating func clearSvnRev() {_uniqueStorage()._svnRev = nil}

  /// Electrical Serial Number of device
  /// Format definition at https://swa.polar.fi/sag/wiki/SAGRFC/SAGRFC8
  var electricalSerialNumber: String {
    get {return _storage._electricalSerialNumber ?? String()}
    set {_uniqueStorage()._electricalSerialNumber = newValue}
  }
  /// Returns true if `electricalSerialNumber` has been explicitly set.
  var hasElectricalSerialNumber: Bool {return _storage._electricalSerialNumber != nil}
  /// Clears the value of `electricalSerialNumber`. Subsequent reads from it will return its default value.
  mutating func clearElectricalSerialNumber() {_uniqueStorage()._electricalSerialNumber = nil}

  /// Device ID for identification purposes.
  var deviceID: String {
    get {return _storage._deviceID ?? String()}
    set {_uniqueStorage()._deviceID = newValue}
  }
  /// Returns true if `deviceID` has been explicitly set.
  var hasDeviceID: Bool {return _storage._deviceID != nil}
  /// Clears the value of `deviceID`. Subsequent reads from it will return its default value.
  mutating func clearDeviceID() {_uniqueStorage()._deviceID = nil}

  ///
  /// Human readable model name, like "RCX 5"
  /// Also known as "product name"
  var modelName: String {
    get {return _storage._modelName ?? String()}
    set {_uniqueStorage()._modelName = newValue}
  }
  /// Returns true if `modelName` has been explicitly set.
  var hasModelName: Bool {return _storage._modelName != nil}
  /// Clears the value of `modelName`. Subsequent reads from it will return its default value.
  mutating func clearModelName() {_uniqueStorage()._modelName = nil}

  ///
  /// Hardware code string, as written by production tester
  /// See SAGRFC48 for more information
  var hardwareCode: String {
    get {return _storage._hardwareCode ?? String()}
    set {_uniqueStorage()._hardwareCode = newValue}
  }
  /// Returns true if `hardwareCode` has been explicitly set.
  var hasHardwareCode: Bool {return _storage._hardwareCode != nil}
  /// Clears the value of `hardwareCode`. Subsequent reads from it will return its default value.
  mutating func clearHardwareCode() {_uniqueStorage()._hardwareCode = nil}

  ///
  /// Textual description of the color of the product. Can be used
  /// for example to customize PC software displaying the device image
  var productColor: String {
    get {return _storage._productColor ?? String()}
    set {_uniqueStorage()._productColor = newValue}
  }
  /// Returns true if `productColor` has been explicitly set.
  var hasProductColor: Bool {return _storage._productColor != nil}
  /// Clears the value of `productColor`. Subsequent reads from it will return its default value.
  mutating func clearProductColor() {_uniqueStorage()._productColor = nil}

  ///
  /// Textual description of the mechanical "design" of the product. Can be used
  /// for example to customize PC software displaying the device image
  var productDesign: String {
    get {return _storage._productDesign ?? String()}
    set {_uniqueStorage()._productDesign = newValue}
  }
  /// Returns true if `productDesign` has been explicitly set.
  var hasProductDesign: Bool {return _storage._productDesign != nil}
  /// Clears the value of `productDesign`. Subsequent reads from it will return its default value.
  mutating func clearProductDesign() {_uniqueStorage()._productDesign = nil}

  /// System ID for identification purposes.
  /// Format definition at https://swa.polar.fi/sag/wiki/SAGRFC/SAGRFC15
  var systemID: String {
    get {return _storage._systemID ?? String()}
    set {_uniqueStorage()._systemID = newValue}
  }
  /// Returns true if `systemID` has been explicitly set.
  var hasSystemID: Bool {return _storage._systemID != nil}
  /// Clears the value of `systemID`. Subsequent reads from it will return its default value.
  mutating func clearSystemID() {_uniqueStorage()._systemID = nil}

  /// Git SHA-1 hash of the commit from which the device software is compiled from
  var gitHash: Data {
    get {return _storage._gitHash ?? Data()}
    set {_uniqueStorage()._gitHash = newValue}
  }
  /// Returns true if `gitHash` has been explicitly set.
  var hasGitHash: Bool {return _storage._gitHash != nil}
  /// Clears the value of `gitHash`. Subsequent reads from it will return its default value.
  mutating func clearGitHash() {_uniqueStorage()._gitHash = nil}

  /// PolarMathSmart algorithm library version
  var polarmathsmartVersion: PbVersion {
    get {return _storage._polarmathsmartVersion ?? PbVersion()}
    set {_uniqueStorage()._polarmathsmartVersion = newValue}
  }
  /// Returns true if `polarmathsmartVersion` has been explicitly set.
  var hasPolarmathsmartVersion: Bool {return _storage._polarmathsmartVersion != nil}
  /// Clears the value of `polarmathsmartVersion`. Subsequent reads from it will return its default value.
  mutating func clearPolarmathsmartVersion() {_uniqueStorage()._polarmathsmartVersion = nil}

  /// A list of sub components
  var subComponentInfo: [PbSubcomponentInfo] {
    get {return _storage._subComponentInfo}
    set {_uniqueStorage()._subComponentInfo = newValue}
  }

  /// Overall user visible shape of the display
  var displayShape: Data_PbDeviceInfo.PbDisplayShape {
    get {return _storage._displayShape ?? .rectangle}
    set {_uniqueStorage()._displayShape = newValue}
  }
  /// Returns true if `displayShape` has been explicitly set.
  var hasDisplayShape: Bool {return _storage._displayShape != nil}
  /// Clears the value of `displayShape`. Subsequent reads from it will return its default value.
  mutating func clearDisplayShape() {_uniqueStorage()._displayShape = nil}

  /// Algorithm version information
  var algorithmVersion: PbAlgorithmVersion {
    get {return _storage._algorithmVersion ?? PbAlgorithmVersion()}
    set {_uniqueStorage()._algorithmVersion = newValue}
  }
  /// Returns true if `algorithmVersion` has been explicitly set.
  var hasAlgorithmVersion: Bool {return _storage._algorithmVersion != nil}
  /// Clears the value of `algorithmVersion`. Subsequent reads from it will return its default value.
  mutating func clearAlgorithmVersion() {_uniqueStorage()._algorithmVersion = nil}


  /// Device capabilities
  var capabilities: [String] {
    get {return _storage._capabilities}
    set {_uniqueStorage()._capabilities = newValue}
  }

  /// Device sales region. Some features e.g. ECG may need to be disabled
  /// due to regulatory reasons in a certain country. There needs to be a
  /// way to define the country where the device is sold.
  var salesRegion: String {
    get {return _storage._salesRegion ?? String()}
    set {_uniqueStorage()._salesRegion = newValue}
  }
  /// Returns true if `salesRegion` has been explicitly set.
  var hasSalesRegion: Bool {return _storage._salesRegion != nil}
  /// Clears the value of `salesRegion`. Subsequent reads from it will return its default value.
  mutating func clearSalesRegion() {_uniqueStorage()._salesRegion = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum PbDisplayShape: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case rectangle // = 0
    case fullyRound // = 1
    case roundFlatBottom // = 2

    init() {
      self = .rectangle
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .rectangle
      case 1: self = .fullyRound
      case 2: self = .roundFlatBottom
      default: return nil
      }
    }

    var rawValue: Int {
      switch self {
      case .rectangle: return 0
      case .fullyRound: return 1
      case .roundFlatBottom: return 2
      }
    }

  }

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

#if swift(>=4.2)

extension Data_PbDeviceInfo.PbDisplayShape: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

#if swift(>=5.5) && canImport(_Concurrency)
extension Data_PbDeviceInfo: @unchecked Sendable {}
extension Data_PbDeviceInfo.PbDisplayShape: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "data"

extension Data_PbDeviceInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".PbDeviceInfo"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "bootloader_version"),
    2: .standard(proto: "platform_version"),
    3: .standard(proto: "device_version"),
    4: .standard(proto: "svn_rev"),
    5: .standard(proto: "electrical_serial_number"),
    6: .same(proto: "deviceID"),
    7: .standard(proto: "model_name"),
    8: .standard(proto: "hardware_code"),
    9: .standard(proto: "product_color"),
    10: .standard(proto: "product_design"),
    11: .standard(proto: "system_id"),
    12: .standard(proto: "git_hash"),
    13: .standard(proto: "polarmathsmart_version"),
    14: .standard(proto: "sub_component_info"),
    15: .standard(proto: "display_shape"),
    16: .standard(proto: "algorithm_version"),
    17: .standard(proto: "font_info"),
    18: .same(proto: "capabilities"),
    19: .standard(proto: "sales_region"),
  ]

  fileprivate class _StorageClass {
    var _bootloaderVersion: PbVersion? = nil
    var _platformVersion: PbVersion? = nil
    var _deviceVersion: PbVersion? = nil
    var _svnRev: UInt32? = nil
    var _electricalSerialNumber: String? = nil
    var _deviceID: String? = nil
    var _modelName: String? = nil
    var _hardwareCode: String? = nil
    var _productColor: String? = nil
    var _productDesign: String? = nil
    var _systemID: String? = nil
    var _gitHash: Data? = nil
    var _polarmathsmartVersion: PbVersion? = nil
    var _subComponentInfo: [PbSubcomponentInfo] = []
    var _displayShape: Data_PbDeviceInfo.PbDisplayShape? = nil
    var _algorithmVersion: PbAlgorithmVersion? = nil
    var _capabilities: [String] = []
    var _salesRegion: String? = nil

    #if swift(>=5.10)
      // This property is used as the initial default value for new instances of the type.
      // The type itself is protecting the reference to its storage via CoW semantics.
      // This will force a copy to be made of this reference when the first mutation occurs;
      // hence, it is safe to mark this as `nonisolated(unsafe)`.
      static nonisolated(unsafe) let defaultInstance = _StorageClass()
    #else
      static let defaultInstance = _StorageClass()
    #endif

    private init() {}

    init(copying source: _StorageClass) {
      _bootloaderVersion = source._bootloaderVersion
      _platformVersion = source._platformVersion
      _deviceVersion = source._deviceVersion
      _svnRev = source._svnRev
      _electricalSerialNumber = source._electricalSerialNumber
      _deviceID = source._deviceID
      _modelName = source._modelName
      _hardwareCode = source._hardwareCode
      _productColor = source._productColor
      _productDesign = source._productDesign
      _systemID = source._systemID
      _gitHash = source._gitHash
      _polarmathsmartVersion = source._polarmathsmartVersion
      _subComponentInfo = source._subComponentInfo
      _displayShape = source._displayShape
      _algorithmVersion = source._algorithmVersion
      _capabilities = source._capabilities
      _salesRegion = source._salesRegion
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public var isInitialized: Bool {
    return withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._bootloaderVersion, !v.isInitialized {return false}
      if let v = _storage._platformVersion, !v.isInitialized {return false}
      if let v = _storage._deviceVersion, !v.isInitialized {return false}
      if let v = _storage._polarmathsmartVersion, !v.isInitialized {return false}
      if !SwiftProtobuf.Internal.areAllInitialized(_storage._subComponentInfo) {return false}
      if let v = _storage._algorithmVersion, !v.isInitialized {return false}
      return true
    }
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        // The use of inline closures is to circumvent an issue where the compiler
        // allocates stack space for every case branch when no optimizations are
        // enabled. https://github.com/apple/swift-protobuf/issues/1034
        switch fieldNumber {
        case 1: try { try decoder.decodeSingularMessageField(value: &_storage._bootloaderVersion) }()
        case 2: try { try decoder.decodeSingularMessageField(value: &_storage._platformVersion) }()
        case 3: try { try decoder.decodeSingularMessageField(value: &_storage._deviceVersion) }()
        case 4: try { try decoder.decodeSingularUInt32Field(value: &_storage._svnRev) }()
        case 5: try { try decoder.decodeSingularStringField(value: &_storage._electricalSerialNumber) }()
        case 6: try { try decoder.decodeSingularStringField(value: &_storage._deviceID) }()
        case 7: try { try decoder.decodeSingularStringField(value: &_storage._modelName) }()
        case 8: try { try decoder.decodeSingularStringField(value: &_storage._hardwareCode) }()
        case 9: try { try decoder.decodeSingularStringField(value: &_storage._productColor) }()
        case 10: try { try decoder.decodeSingularStringField(value: &_storage._productDesign) }()
        case 11: try { try decoder.decodeSingularStringField(value: &_storage._systemID) }()
        case 12: try { try decoder.decodeSingularBytesField(value: &_storage._gitHash) }()
        case 13: try { try decoder.decodeSingularMessageField(value: &_storage._polarmathsmartVersion) }()
        case 14: try { try decoder.decodeRepeatedMessageField(value: &_storage._subComponentInfo) }()
        case 15: try { try decoder.decodeSingularEnumField(value: &_storage._displayShape) }()
        case 16: try { try decoder.decodeSingularMessageField(value: &_storage._algorithmVersion) }()
        case 18: try { try decoder.decodeRepeatedStringField(value: &_storage._capabilities) }()
        case 19: try { try decoder.decodeSingularStringField(value: &_storage._salesRegion) }()
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every if/case branch local when no optimizations
      // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
      // https://github.com/apple/swift-protobuf/issues/1182
      try { if let v = _storage._bootloaderVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      } }()
      try { if let v = _storage._platformVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      } }()
      try { if let v = _storage._deviceVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
      } }()
      try { if let v = _storage._svnRev {
        try visitor.visitSingularUInt32Field(value: v, fieldNumber: 4)
      } }()
      try { if let v = _storage._electricalSerialNumber {
        try visitor.visitSingularStringField(value: v, fieldNumber: 5)
      } }()
      try { if let v = _storage._deviceID {
        try visitor.visitSingularStringField(value: v, fieldNumber: 6)
      } }()
      try { if let v = _storage._modelName {
        try visitor.visitSingularStringField(value: v, fieldNumber: 7)
      } }()
      try { if let v = _storage._hardwareCode {
        try visitor.visitSingularStringField(value: v, fieldNumber: 8)
      } }()
      try { if let v = _storage._productColor {
        try visitor.visitSingularStringField(value: v, fieldNumber: 9)
      } }()
      try { if let v = _storage._productDesign {
        try visitor.visitSingularStringField(value: v, fieldNumber: 10)
      } }()
      try { if let v = _storage._systemID {
        try visitor.visitSingularStringField(value: v, fieldNumber: 11)
      } }()
      try { if let v = _storage._gitHash {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 12)
      } }()
      try { if let v = _storage._polarmathsmartVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
      } }()
      if !_storage._subComponentInfo.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._subComponentInfo, fieldNumber: 14)
      }
      try { if let v = _storage._displayShape {
        try visitor.visitSingularEnumField(value: v, fieldNumber: 15)
      } }()
      try { if let v = _storage._algorithmVersion {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 16)
      } }()
      if !_storage._capabilities.isEmpty {
        try visitor.visitRepeatedStringField(value: _storage._capabilities, fieldNumber: 18)
      }
      try { if let v = _storage._salesRegion {
        try visitor.visitSingularStringField(value: v, fieldNumber: 19)
      } }()
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Data_PbDeviceInfo, rhs: Data_PbDeviceInfo) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._bootloaderVersion != rhs_storage._bootloaderVersion {return false}
        if _storage._platformVersion != rhs_storage._platformVersion {return false}
        if _storage._deviceVersion != rhs_storage._deviceVersion {return false}
        if _storage._svnRev != rhs_storage._svnRev {return false}
        if _storage._electricalSerialNumber != rhs_storage._electricalSerialNumber {return false}
        if _storage._deviceID != rhs_storage._deviceID {return false}
        if _storage._modelName != rhs_storage._modelName {return false}
        if _storage._hardwareCode != rhs_storage._hardwareCode {return false}
        if _storage._productColor != rhs_storage._productColor {return false}
        if _storage._productDesign != rhs_storage._productDesign {return false}
        if _storage._systemID != rhs_storage._systemID {return false}
        if _storage._gitHash != rhs_storage._gitHash {return false}
        if _storage._polarmathsmartVersion != rhs_storage._polarmathsmartVersion {return false}
        if _storage._subComponentInfo != rhs_storage._subComponentInfo {return false}
        if _storage._displayShape != rhs_storage._displayShape {return false}
        if _storage._algorithmVersion != rhs_storage._algorithmVersion {return false}
        if _storage._capabilities != rhs_storage._capabilities {return false}
        if _storage._salesRegion != rhs_storage._salesRegion {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Data_PbDeviceInfo.PbDisplayShape: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "RECTANGLE"),
    1: .same(proto: "FULLY_ROUND"),
    2: .same(proto: "ROUND_FLAT_BOTTOM"),
  ]
}
