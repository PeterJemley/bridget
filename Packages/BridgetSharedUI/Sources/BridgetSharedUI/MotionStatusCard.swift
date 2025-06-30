//
//  MotionStatusCard.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct MotionStatusCard: View {
    @ObservedObject public var motionService: MotionDetectionService
    
    public init(motionService: MotionDetectionService) {
        self.motionService = motionService
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: motionService.vehicleState.systemImage)
                    .foregroundColor(motionService.isInVehicle ? .blue : .secondary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Motion Detection")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(motionService.statusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if motionService.isMonitoring {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            if motionService.isInVehicle {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Speed:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", motionService.currentSpeed * 3.6)) km/h")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Acceleration:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.2f", motionService.acceleration)) m/s²")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MotionStatusCard(motionService: MotionDetectionService())
        .padding()
} 