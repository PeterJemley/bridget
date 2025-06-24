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
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Accessing Seattle Open Data API")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Loading bridge activity data...")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .padding(16)
        }
    }
}

#Preview {
    LoadingDataOverlay()
}