//  Copyright © 2023 Polar. All rights reserved.

public struct PolarDiskSpaceData {
    public let totalSpace: UInt64
    public let freeSpace: UInt64

    public init(totalSpace: UInt64, freeSpace: UInt64) {
        self.totalSpace = totalSpace
        self.freeSpace = freeSpace
    }
    
    static func fromProto(proto: Protocol_PbPFtpDiskSpaceResult) -> PolarDiskSpaceData {
        return PolarDiskSpaceData(
            totalSpace: UInt64(proto.fragmentSize) * proto.totalFragments,
            freeSpace: UInt64(proto.fragmentSize) * proto.freeFragments
        )
    }
}
