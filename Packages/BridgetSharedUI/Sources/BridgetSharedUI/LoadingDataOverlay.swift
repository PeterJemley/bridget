//
//  LoadingDataOverlay.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

public struct LoadingDataOverlay: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                VStack(spacing: 8) {
                    Text("Loading Bridge Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Accessing Seattle Open Data API")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Getting the latest bridge information...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

#Preview {
    LoadingDataOverlay()
}