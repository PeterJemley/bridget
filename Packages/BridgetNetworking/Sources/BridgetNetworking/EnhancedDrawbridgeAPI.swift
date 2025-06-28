//
//  EnhancedDrawbridgeAPI.swift
//  BridgetNetworking
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import BridgetCore

// MARK: - Enhanced API Client

public actor EnhancedDrawbridgeAPI {
    
    // MARK: - Configuration
    
    public struct Configuration {
        let baseURL: String
        let batchSize: Int
        let maxRetries: Int
        let timeoutInterval: TimeInterval
        let cacheTimeout: TimeInterval
        
        public init(
            baseURL: String = "https://data.seattle.gov/resource/gm8h-9449.json",
            batchSize: Int = 1000,
            maxRetries: Int = 3,
            timeoutInterval: TimeInterval = 30.0,
            cacheTimeout: TimeInterval = 300.0 // 5 minutes
        ) {
            self.baseURL = baseURL
            self.batchSize = batchSize
            self.maxRetries = maxRetries
            self.timeoutInterval = timeoutInterval
            self.cacheTimeout = cacheTimeout
        }
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    private let session: URLSession
    private let cache = NSCache<NSString, CachedData>()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.urlCache = nil // Disable URL cache, use our custom cache
        
        self.session = URLSession(configuration: sessionConfig)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public Interface
    
    /// Fetch drawbridge data with enhanced error handling and caching
    public func fetchDrawbridgeData(limit: Int = 50000) async throws -> [EventDTO] {
        print("🌐 [ENHANCED API] Starting enhanced drawbridge data fetch")
        
        // Check cache first
        if let cachedData = getCachedData() {
            print("🌐 [ENHANCED API] Returning cached data: \(cachedData.events.count) events")
            return cachedData.events
        }
        
        // Fetch fresh data
        let events = try await fetchAllData(limit: limit)
        
        // Cache the results
        cacheData(events)
        
        print("🌐 [ENHANCED API] Fetch complete: \(events.count) events")
        return events
    }
    
    /// Fetch data for a specific bridge
    public func fetchBridgeData(bridgeID: Int, limit: Int = 1000) async throws -> [EventDTO] {
        print("🌐 [ENHANCED API] Fetching data for bridge ID: \(bridgeID)")
        
        let allEvents = try await fetchDrawbridgeData(limit: limit)
        let bridgeEvents = allEvents.filter { $0.entityID == bridgeID }
        
        print("🌐 [ENHANCED API] Found \(bridgeEvents.count) events for bridge \(bridgeID)")
        return bridgeEvents
    }
    
    /// Fetch data for a specific time range
    public func fetchDataInRange(from startDate: Date, to endDate: Date, limit: Int = 10000) async throws -> [EventDTO] {
        print("🌐 [ENHANCED API] Fetching data from \(startDate) to \(endDate)")
        
        let allEvents = try await fetchDrawbridgeData(limit: limit)
        let filteredEvents = allEvents.filter { event in
            event.openDateTime >= startDate && event.openDateTime <= endDate
        }
        
        print("🌐 [ENHANCED API] Found \(filteredEvents.count) events in date range")
        return filteredEvents
    }
    
    /// Clear the cache
    public func clearCache() {
        cache.removeAllObjects()
        print("🌐 [ENHANCED API] Cache cleared")
    }
    
    /// Get cache statistics
    public func getCacheStats() -> CacheStats {
        let totalCost = cache.totalCostLimit
        let currentCost = cache.totalCostLimit
        let objectCount = 0
        
        return CacheStats(
            totalCost: totalCost,
            currentCost: currentCost,
            objectCount: objectCount
        )
    }
    
    // MARK: - Private Methods
    
    private func fetchAllData(limit: Int) async throws -> [EventDTO] {
        var allEvents: [EventDTO] = []
        var offset = 0
        var retryCount = 0
        
        while true {
            do {
                let batchEvents = try await fetchBatchWithRetry(offset: offset, limit: configuration.batchSize)
                
                if batchEvents.isEmpty {
                    print("🌐 [ENHANCED API] No more data - stopping pagination")
                    break
                }
                
                allEvents.append(contentsOf: batchEvents)
                print("🌐 [ENHANCED API] Batch \(offset/configuration.batchSize + 1) complete: +\(batchEvents.count) events (Total: \(allEvents.count))")
                
                // If we got less than batchSize, we've reached the end
                if batchEvents.count < configuration.batchSize {
                    print("🌐 [ENHANCED API] Last batch detected (\(batchEvents.count) < \(configuration.batchSize)) - stopping")
                    break
                }
                
                offset += configuration.batchSize
                retryCount = 0 // Reset retry count for next batch
                
                // Safety limit to prevent infinite loop
                if offset > 10000 {
                    print("🌐 [ENHANCED API WARNING] Safety limit reached at \(offset) - stopping")
                    break
                }
                
            } catch {
                retryCount += 1
                if retryCount >= configuration.maxRetries {
                    throw APIError.maxRetriesExceeded(error: error)
                }
                
                print("🌐 [ENHANCED API] Batch failed, retrying (\(retryCount)/\(configuration.maxRetries)): \(error)")
                
                // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount))) * 1_000_000_000)
            }
        }
        
        return allEvents
    }
    
    private func fetchBatchWithRetry(offset: Int, limit: Int) async throws -> [EventDTO] {
        var lastError: Error?
        
        for attempt in 1...configuration.maxRetries {
            do {
                return try await fetchBatch(offset: offset, limit: limit)
            } catch {
                lastError = error
                print("🌐 [ENHANCED API] Attempt \(attempt) failed: \(error)")
                
                if attempt < configuration.maxRetries {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt)) * 1_000_000_000
                    try await Task.sleep(nanoseconds: UInt64(delay))
                }
            }
        }
        
        throw APIError.maxRetriesExceeded(error: lastError ?? APIError.unknown)
    }
    
    private func fetchBatch(offset: Int, limit: Int) async throws -> [EventDTO] {
        guard let url = URL(string: "\(configuration.baseURL)?$limit=\(limit)&$offset=\(offset)") else {
            throw APIError.invalidURL
        }
        
        print("🌐 [ENHANCED API] Fetching: \(url)")
        
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🌐 [ENHANCED API] Response: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let rawEvents = try decoder.decode([DrawbridgeEventResponse].self, from: data)
            let eventDTOs = rawEvents.compactMap { convertToEventDTO(from: $0) }
            
            return eventDTOs
            
        } catch {
            print("🌐 [ENHANCED API] JSON parsing failed: \(error)")
            if offset == 0 {
                print("🌐 [ENHANCED API] Raw data preview: \(String(data: data.prefix(500), encoding: .utf8) ?? "Unable to decode")")
            }
            throw APIError.parsingError(error: error)
        }
    }
    
    private func convertToEventDTO(from response: DrawbridgeEventResponse) -> EventDTO? {
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
            print("🌐 [ENHANCED API WARNING] Skipping event with missing/invalid fields")
            return nil
        }
        
        // Parse open date with multiple format support
        let openDateTime = parseDate(openDateTimeString)
        guard let openDateTime = openDateTime else {
            print("🌐 [ENHANCED API WARNING] Could not parse open date: \(openDateTimeString)")
            return nil
        }
        
        // Parse close date (optional)
        let closeDateTime = response.closedatetime.flatMap { parseDate($0) }
        
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
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters: [Any] = [
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSS"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss"),
            createISOFormatter(withFractionalSeconds: true),
            createISOFormatter(withFractionalSeconds: false)
        ]
        
        for formatter in formatters {
            if let df = formatter as? DateFormatter {
                if let date = df.date(from: dateString) {
                    return date
                }
            } else if let iso = formatter as? ISO8601DateFormatter {
                if let date = iso.date(from: dateString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private func createISOFormatter(withFractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        if withFractionalSeconds {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            formatter.formatOptions = [.withInternetDateTime]
        }
        return formatter
    }
    
    // MARK: - Caching
    
    private func getCachedData() -> CachedData? {
        let key = "drawbridge_data" as NSString
        guard let cachedData = cache.object(forKey: key) else { return nil }
        
        let age = Date().timeIntervalSince(cachedData.timestamp)
        if age > configuration.cacheTimeout {
            print("🌐 [ENHANCED API] Cache expired, age: \(age)s")
            cache.removeObject(forKey: key)
            return nil
        }
        
        return cachedData
    }
    
    private func cacheData(_ events: [EventDTO]) {
        let key = "drawbridge_data" as NSString
        let cachedData = CachedData(events: events, timestamp: Date())
        cache.setObject(cachedData, forKey: key)
        print("🌐 [ENHANCED API] Cached \(events.count) events")
    }
}

// MARK: - Supporting Types

private class CachedData {
    let events: [EventDTO]
    let timestamp: Date
    
    init(events: [EventDTO], timestamp: Date) {
        self.events = events
        self.timestamp = timestamp
    }
}

public struct CacheStats {
    public let totalCost: Int
    public let currentCost: Int
    public let objectCount: Int
}

public enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case parsingError(error: Error)
    case maxRetriesExceeded(error: Error?)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .parsingError(let error):
            return "Parsing error: \(error.localizedDescription)"
        case .maxRetriesExceeded(let error):
            return "Max retries exceeded: \(error?.localizedDescription ?? "Unknown error")"
        case .unknown:
            return "Unknown error"
        }
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

// MARK: - Convenience Extensions

extension EnhancedDrawbridgeAPI {
    
    /// Create a shared instance with default configuration
    public static let shared = EnhancedDrawbridgeAPI()
    
    /// Create an instance with custom configuration
    public static func custom(configuration: Configuration) -> EnhancedDrawbridgeAPI {
        return EnhancedDrawbridgeAPI(configuration: configuration)
    }
}

// MARK: - Legacy Compatibility

extension EnhancedDrawbridgeAPI {
    
    /// Legacy method for backward compatibility
    public func fetchDrawbridgeDataLegacy(limit: Int = 50000) async throws -> [DrawbridgeEvent] {
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
} 