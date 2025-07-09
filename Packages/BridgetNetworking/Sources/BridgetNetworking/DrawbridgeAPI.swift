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
    /// Thread-safe version that returns EventDTOs for concurrency
    public static func fetchDrawbridgeData(limit: Int = 50000) async throws -> [EventDTO] {
        SecurityLogger.api("Starting drawbridge data fetch - Target: ALL DATA (~4,113 rows)")
        SecurityLogger.api("Using correct endpoint")
        
        var allEventDTOs: [EventDTO] = []
        var offset = 0
        let batchSize = 1000 // Seattle API limit per request
        let startTime = Date()
        
        while true {
            SecurityLogger.api("Fetching batch \(offset/batchSize + 1) - Offset: \(offset), Limit: \(batchSize)")
            
            let batchEventDTOs = try await fetchBatch(offset: offset, limit: batchSize)
            
            if batchEventDTOs.isEmpty {
                SecurityLogger.api("No more data - stopping pagination")
                break
            }
            
            allEventDTOs.append(contentsOf: batchEventDTOs)
            SecurityLogger.api("Batch \(offset/batchSize + 1) complete: +\(batchEventDTOs.count) events (Total: \(allEventDTOs.count))")
            
            // If we got less than batchSize, we've reached the end
            if batchEventDTOs.count < batchSize {
                SecurityLogger.api("Last batch detected (\(batchEventDTOs.count) < \(batchSize)) - stopping")
                break
            }
            
            offset += batchSize
            
            // Safety limit to prevent infinite loop
            if offset > 10000 {
                SecurityLogger.api("Safety limit reached at \(offset) - stopping")
                break
            }
        }
        
        let fetchTime = Date().timeIntervalSince(startTime)
        SecurityLogger.api("Fetch complete: \(allEventDTOs.count) events in \(String(format: "%.2f", fetchTime))s")
        
        logDataAnalysis(eventDTOs: allEventDTOs)
        return allEventDTOs
    }
    
    /// Legacy method for backward compatibility - returns DrawbridgeEvent models
    /// Use fetchDrawbridgeData(limit:) for thread-safe concurrency
    public static func fetchDrawbridgeDataLegacy(limit: Int = 50000) async throws -> [DrawbridgeEvent] {
        let eventDTOs = try await fetchDrawbridgeData(limit: limit)
        return eventDTOs.map { dto in
            DrawbridgeEvent(
                entityType: dto.entityType,
                entityName: dto.entityName,
                entityID: dto.entityID,
                openDateTime: dto.openDateTime,
                closeDateTime: dto.closeDateTime,
                minutesOpen: dto.minutesOpen,
                latitude: dto.latitude,
                longitude: dto.longitude
            )
        }
    }
    
    /// Fetch a single batch with offset
    private static func fetchBatch(offset: Int, limit: Int) async throws -> [EventDTO] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$offset=\(offset)") else {
            SecurityLogger.error("Invalid URL for batch fetch", error: URLError(.badURL))
            throw URLError(.badURL)
        }
        
        SecurityLogger.api("Fetching batch", url: url)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            SecurityLogger.error("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        SecurityLogger.api("Response: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            SecurityLogger.error("HTTP \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let rawEvents = try decoder.decode([DrawbridgeEventResponse].self, from: data)
            
            // Convert to EventDTO objects
            let eventDTOs = rawEvents.compactMap { response in
                convertToEventDTO(from: response)
            }
            
            return eventDTOs
            
        } catch {
            SecurityLogger.error("JSON parsing failed for batch at offset \(offset)", error: error)
            if offset == 0 {
                SecurityLogger.debug("Raw data preview: \(String(data: data.prefix(500), encoding: .utf8) ?? "Unable to decode")")
            }
            throw error
        }
    }
    
    /// Log detailed data analysis
    private static func logDataAnalysis(eventDTOs: [EventDTO]) {
        SecurityLogger.api("DATA ANALYSIS ================")
        SecurityLogger.api("Total Events: \(eventDTOs.count)")
        
        if let earliest = eventDTOs.map(\.openDateTime).min(),
           let latest = eventDTOs.map(\.openDateTime).max() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            SecurityLogger.api("Date Range: \(formatter.string(from: earliest)) to \(formatter.string(from: latest))")
            
            let timeSpan = latest.timeIntervalSince(earliest) / (24 * 3600)
            SecurityLogger.api("Time Span: \(String(format: "%.1f", timeSpan)) days")
        }
        
        // Bridge breakdown
        let bridgeGroups = Dictionary(grouping: eventDTOs, by: \.entityName)
        SecurityLogger.api("Bridges (\(bridgeGroups.count)):")
        for (bridgeName, events) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
            SecurityLogger.api("    • \(bridgeName): \(events.count) events")
        }
        
        // Time analysis
        let hourDistribution = Dictionary(grouping: eventDTOs) { event in
            Calendar.current.component(.hour, from: event.openDateTime)
        }
        let mostActiveHour = hourDistribution.max(by: { $0.value.count < $1.value.count })
        if let (hour, events) = mostActiveHour {
            SecurityLogger.api("Most active hour: \(hour):00 (\(events.count) events)")
        }
        
        SecurityLogger.api("DATA ANALYSIS ================")
    }
    
    /// Convert API response to EventDTO
    private static func convertToEventDTO(from response: DrawbridgeEventResponse) -> EventDTO? {
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
            SecurityLogger.api("Skipping event with missing/invalid fields")
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
            SecurityLogger.api("Could not parse date: \(openDateTimeString)")
            return nil
        }
        
        // Parse close date (optional)
        let closeDateTime: Date?
        if let closeDateTimeString = response.closedatetime, !closeDateTimeString.isEmpty {
            if let date = dateFormatter1.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = isoFormatter1.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = isoFormatter2.date(from: closeDateTimeString) {
                closeDateTime = date
            } else if let date = dateFormatter2.date(from: closeDateTimeString) {
                closeDateTime = date
            } else {
                closeDateTime = nil
            }
        } else {
            closeDateTime = nil
        }
        
        // Parse minutes open
        let minutesOpen: Double
        if let minutesOpenString = response.minutesopen,
           let minutes = Double(minutesOpenString) {
            minutesOpen = minutes
        } else if let closeDate = closeDateTime {
            minutesOpen = closeDate.timeIntervalSince(openDateTime) / 60.0
        } else {
            minutesOpen = 0.0
        }
        
        return EventDTO(
            entityType: entityType,
            entityName: entityName,
            entityID: entityID,
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: minutesOpen,
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
