//
//  RawDataDetailView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

struct RawDataDetailView: View {
    let events: [DrawbridgeEvent]
    @State private var searchQuery = ""
    @State private var showingCount = 50
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and filter controls
                VStack(spacing: 12) {
                    TextField("Search bridge name...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Showing \(min(showingCount, filteredEvents.count)) of \(filteredEvents.count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Show More") {
                            showingCount += 50
                        }
                        .disabled(showingCount >= filteredEvents.count)
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Events list
                List {
                    ForEach(Array(filteredEvents.prefix(showingCount).enumerated()), id: \.offset) { index, event in
                        RawDataEventRow(event: event, index: index + 1)
                    }
                }
            }
            .navigationTitle("Raw Data Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filteredEvents: [DrawbridgeEvent] {
        let sorted = events.sorted { $0.openDateTime > $1.openDateTime }
        
        if searchQuery.isEmpty {
            return sorted
        } else {
            return sorted.filter { event in
                event.entityName.lowercased().contains(searchQuery.lowercased())
            }
        }
    }
}

struct RawDataEventRow: View {
    let event: DrawbridgeEvent
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(index)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                Text(event.entityName)
                    .font(.headline)
                
                Spacer()
                
                Text(event.isCurrentlyOpen ? "OPEN" : "CLOSED")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(event.isCurrentlyOpen ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text("Opened: \(event.openDateTime.formatted(.dateTime))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let closeDateTime = event.closeDateTime {
                Text("Closed: \(closeDateTime.formatted(.dateTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Duration: \(event.minutesOpen, specifier: "%.0f") minutes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Entity ID: \(event.entityID) | Location: \(event.latitude, specifier: "%.6f"), \(event.longitude, specifier: "%.6f")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RawDataDetailView(events: [])
}