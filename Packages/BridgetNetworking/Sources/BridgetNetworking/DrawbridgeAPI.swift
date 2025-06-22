//
//  DrawbridgeAPI.swift
//  BridgetNetworking
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import BridgetCore

public struct DrawbridgeAPI {
    private static let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
    
    /// Fetch drawbridge data from Seattle Open Data API with pagination
    public static func fetchDrawbridgeData(limit: Int = 50000) async throws -> [DrawbridgeEvent] {
        print("🌐 [API] Starting drawbridge data fetch - Target: ALL DATA (~4,113 rows)")
        print("🌐 [API] Using correct endpoint: \(baseURL)")
        
        var allEvents: [DrawbridgeEvent] = []
        var offset = 0
        let batchSize = 1000 // Seattle API limit per request
        let startTime = Date()
        
        while true {
            print("🌐 [API] Fetching batch \(offset/batchSize + 1) - Offset: \(offset), Limit: \(batchSize)")
            
            let batchEvents = try await fetchBatch(offset: offset, limit: batchSize)
            
            if batchEvents.isEmpty {
                print("🌐 [API] No more data - stopping pagination")
                break
            }
            
            allEvents.append(contentsOf: batchEvents)
            print("🌐 [API] Batch \(offset/batchSize + 1) complete: +\(batchEvents.count) events (Total: \(allEvents.count))")
            
            // If we got less than batchSize, we've reached the end
            if batchEvents.count < batchSize {
                print("🌐 [API] Last batch detected (\(batchEvents.count) < \(batchSize)) - stopping")
                break
            }
            
            offset += batchSize
            
            // Safety limit to prevent infinite loop
            if offset > 10000 {
                print("🌐 [API WARNING] Safety limit reached at \(offset) - stopping")
                break
            }
        }
        
        let fetchTime = Date().timeIntervalSince(startTime)
        print("🌐 [API] Pagination complete!")
        print("🌐 [API] FINAL RESULTS:")
        print("🌐 [API]    • Total events fetched: \(allEvents.count)")
        print("🌐 [API]    • Expected from UI: ~4,113 events")
        print("🌐 [API]    • Data completeness: \(allEvents.count >= 4000 ? "✅ EXCELLENT" : allEvents.count >= 3000 ? "✅ GOOD" : "⚠️ INCOMPLETE") (\(String(format: "%.1f", Double(allEvents.count) / 4113.0 * 100))%)")
        print("🌐 [API]    • Total time: \(String(format: "%.2f", fetchTime))s")
        print("🌐 [API]    • Batches fetched: \(offset/batchSize + 1)")
        
        // Log data analysis
        logDataAnalysis(events: allEvents)
        
        return allEvents
    }
    
    /// Fetch a single batch with offset
    private static func fetchBatch(offset: Int, limit: Int) async throws -> [DrawbridgeEvent] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$offset=\(offset)") else {
            print("🌐 [API ERROR] Invalid URL: \(baseURL)?$limit=\(limit)&$offset=\(offset)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Log HTTP response for first batch
        if offset == 0, let httpResponse = response as? HTTPURLResponse {
            print("🌐 [API] HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("🌐 [API ERROR] HTTP \(httpResponse.statusCode) - \(String(data: data, encoding: .utf8) ?? "No response body")")
                throw URLError(.badServerResponse)
            }
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let rawEvents = try decoder.decode([DrawbridgeEventResponse].self, from: data)
            
            // Convert to DrawbridgeEvent objects
            let events = rawEvents.compactMap { response in
                convertToDrawbridgeEvent(from: response)
            }
            
            return events
            
        } catch {
            print("🌐 [API ERROR] JSON parsing failed for batch at offset \(offset): \(error)")
            if offset == 0 {
                print("🌐 [API ERROR] Raw data preview: \(String(data: data.prefix(500), encoding: .utf8) ?? "Unable to decode")")
            }
            throw error
        }
    }
    
    /// Log detailed data analysis
    private static func logDataAnalysis(events: [DrawbridgeEvent]) {
        print("\n🌐 [DATA ANALYSIS] ================")
        print("🌐 [DATA ANALYSIS] Total Events: \(events.count)")
        
        if let earliest = events.map(\.openDateTime).min(),
           let latest = events.map(\.openDateTime).max() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("🌐 [DATA ANALYSIS] Date Range: \(formatter.string(from: earliest)) to \(formatter.string(from: latest))")
            
            let timeSpan = latest.timeIntervalSince(earliest) / (24 * 3600)
            print("🌐 [DATA ANALYSIS] Time Span: \(String(format: "%.1f", timeSpan)) days")
        }
        
        // Bridge breakdown
        let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
        print("🌐 [DATA ANALYSIS] Bridges (\(bridgeGroups.count)):")
        for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
            let percentage = String(format: "%.1f", Double(bridgeEvents.count) / Double(events.count) * 100)
            print("🌐 [DATA ANALYSIS]   • \(bridgeName): \(bridgeEvents.count) events (\(percentage)%)")
        }
        
        // Verify 1st Ave South count
        if let firstAveEvents = bridgeGroups["1st Ave South"] {
            print("🌐 [DATA ANALYSIS] 1st Ave South Verification:")
            print("🌐 [DATA ANALYSIS]    • Our data: \(firstAveEvents.count) events")
            print("🌐 [DATA ANALYSIS]    • Expected: ~210 events")
            print("🌐 [DATA ANALYSIS]    • Status: \(firstAveEvents.count >= 200 ? "CORRECT" : "MISSING DATA")")
        }
        
        // Status breakdown
        let openEvents = events.filter { $0.closeDateTime == nil }
        let closedEvents = events.filter { $0.closeDateTime != nil }
        print("🌐 [DATA ANALYSIS] Status: \(openEvents.count) open, \(closedEvents.count) closed")
        
        print("🌐 [DATA ANALYSIS] ================\n")
    }
    
    /// Convert API response to DrawbridgeEvent
    private static func convertToDrawbridgeEvent(from response: DrawbridgeEventResponse) -> DrawbridgeEvent? {
        // Validate and convert required fields
        guard let entityIDString = response.entityid,
              let entityID = Int(entityIDString),
              let entityName = response.entityname,
              let entityType = response.entitytype,
              let openDateTimeString = response.opendatetime,
              let latitudeString = response.latitude,
              let latitude = Double(latitudeString),
              let longitudeString = response.longitude,
              let longitude = Double(longitudeString) else {
            print("🌐 [API WARNING] Skipping event with missing/invalid fields")
            return nil
        }
        
        // Parse open date - handle different format
        let openDateTime: Date
        
        // Try multiple date formats since the API format seems inconsistent
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter1.timeZone = TimeZone.current
        
        let isoFormatter1 = ISO8601DateFormatter()
        isoFormatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let isoFormatter2 = ISO8601DateFormatter()
        isoFormatter2.formatOptions = [.withInternetDateTime]
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter2.timeZone = TimeZone.current
        
        // Try each formatter until one works
        if let date = dateFormatter1.date(from: openDateTimeString) {
            openDateTime = date
        } else if let date = isoFormatter1.date(from: openDateTimeString) {
            openDateTime = date
        } else if let date = isoFormatter2.date(from: openDateTimeString) {
            openDateTime = date
        } else if let date = dateFormatter2.date(from: openDateTimeString) {
            openDateTime = date
        } else {
            print("🌐 [API WARNING] Could not parse opendatetime with any format: \(openDateTimeString)")
            return nil
        }
        
        // Parse close date if present using the same logic
        var closeDateTime: Date?
        if let closeDateTimeString = response.closedatetime {
            if let date = dateFormatter1.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = isoFormatter1.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = isoFormatter2.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = dateFormatter2.date(from: closeDateTimeString) {
                closeDateTime = date
            }
        }
        
        // Calculate minutes open - try API field first, then calculate
        var minutesOpen: Double = 0.0
        
        if let minutesOpenString = response.minutesopen,
           let apiMinutes = Double(minutesOpenString) {
            minutesOpen = apiMinutes
        } else if let closeDateTime = closeDateTime {
            minutesOpen = closeDateTime.timeIntervalSince(openDateTime) / 60.0
        } else {
            // For currently open bridges, calculate time since opening
            minutesOpen = Date().timeIntervalSince(openDateTime) / 60.0
        }
        
        return DrawbridgeEvent(
            entityType: entityType,
            entityName: entityName,
            entityID: entityID,
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: max(0, minutesOpen),
            latitude: latitude,
            longitude: longitude
        )
    }
}

// MARK: - API Response Models
private struct DrawbridgeEventResponse: Codable {
    let entityid: String?
    let entityname: String?
    let entitytype: String?
    let opendatetime: String?
    let closedatetime: String?
    let latitude: String?
    let longitude: String?
    let minutesopen: String?
}
