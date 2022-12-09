/// Copyright © 2019 Polar Electro Oy. All rights reserved.

import Foundation

/// Polar SDK errors
public enum PolarErrors: Error {
    /// GATT characteristic notification not enabled
    case notificationNotEnabled
    
    /// GATT service not found
    case serviceNotFound
    
    /// Device state != Connected
    case deviceNotConnected
    
    /// Device not found
    case deviceNotFound
    
    /// Requested operation is not supported
    case operationNotSupported
    
    /// Google protocol buffers encode failed
    case messageEncodeFailed
    
    /// Google protocol buffers decode failed
    case messageDecodeFailed
    
    /// String to date time formatting failed
    case dateTimeFormatFailed(description: String = "")
    
    /// Failed to start streaming
    case unableToStartStreaming
    
    /// invalid argument
    case invalidArgument
    
    /// Error on device operation
    case deviceError(description: String)
}
