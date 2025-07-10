//  BackgroundTrafficAgent.swift (cross-platform stub)
//  BridgetCore
//
//  This file is compiled for all platforms except iOS. The real implementation is in iOS/BackgroundTrafficAgent.swift.
//  This stub prevents build errors on macOS and other platforms.

import Foundation

#if !os(iOS)
/// Stub for non-iOS platforms. This class is not available except on iOS.
public class BackgroundTrafficAgent: NSObject {
    public init(trafficService: Any, motionService: Any) {
        fatalError("BackgroundTrafficAgent is only available on iOS.")
    }
}
#endif 