//
//  ContentView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    @State private var showDebugView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "laurel.leading")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("Bridget")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Image(systemName: "laurel.trailing")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    }
                    
                    Text("Ditch the spanxiety and bridge the gap between you and on time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if events.isEmpty {
                    Text("No bridge data loaded yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Spacer()
                            Text("Data Summary:")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("• \(events.count) bridge events")
                        Text("• \(uniqueBridgeCount) unique bridges")
                        Text("• \(currentlyOpenCount) currently open")
                        
                        if let lastEvent = events.sorted(by: { $0.openDateTime > $1.openDateTime }).first {
                            Text("• Last event: \(lastEvent.openDateTime.formatted(.relative(presentation: .named)))")
                        }
                        
                        Text("")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Spacer()
                                Text("Bridges Monitored:")
                                    .font(.headline)
                                Spacer()
                            }
                            Text(uniqueBridgeNames)
                                .font(.body)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button("Open Debug Console") {
                    showDebugView = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .sheet(isPresented: $showDebugView) {
                DebugView()
            }
        }
    }
    
    private var currentlyOpenCount: Int {
        events.filter(\.isCurrentlyOpen).count
    }
    
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private var uniqueBridgeNames: String {
        let names = Set(events.map(\.entityName))
        return names.sorted().joined(separator: ", ")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}
