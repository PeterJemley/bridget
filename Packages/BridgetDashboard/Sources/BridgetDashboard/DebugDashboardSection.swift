//
//  DebugDashboardSection.swift
//  BridgetDashboard
//
//  Created by AI on 7/8/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct DebugDashboardSection: View {
    public let motionService: MotionDetectionService
    public let backgroundAgent: BackgroundTrafficAgent
    
    public init(motionService: MotionDetectionService, backgroundAgent: BackgroundTrafficAgent) {
        self.motionService = motionService
        self.backgroundAgent = backgroundAgent
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            MotionStatusCard(motionService: motionService)
            BackgroundMonitoringCard(backgroundAgent: backgroundAgent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
} 