//
//  DrawbridgeAPI.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import Foundation

struct DrawbridgeAPI {
    static let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
    
    struct APIResponse: Codable {
        let entitytype: String
        let entityname: String
        let entityid: String
        let opendatetime: String
        let closedatetime: String?
        let minutesopen: String
        let latitude: String
        let longitude: String
    }
    
    struct ImportProgress {
        let totalRecords: Int
        let currentBatch: Int
        let totalBatches: Int
        let recordsImported: Int
        let isComplete: Bool
        let currentBridge: String?
        
        var progressPercentage: Double {
            guard totalRecords > 0 else { return 0 }
            return Double(recordsImported) / Double(totalRecords)
        }
    }
    
    static func fetchDrawbridgeData(limit: Int = 1000) async throws -> [DrawbridgeEvent] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$order=opendatetime DESC") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let responses = try JSONDecoder().decode([APIResponse].self, from: data)
        
        return responses.compactMap { response in
            guard let entityID = Int(response.entityid),
                  let openDate = DateFormatter.iso8601WithFractionalSeconds.date(from: response.opendatetime),
                  let minutesOpen = Double(response.minutesopen),
                  let latitude = Double(response.latitude),
                  let longitude = Double(response.longitude) else {
                return nil
            }
            
            let closeDate = response.closedatetime.flatMap { 
                DateFormatter.iso8601WithFractionalSeconds.date(from: $0) 
            }
            
            return DrawbridgeEvent(
                entityType: response.entitytype,
                entityName: response.entityname,
                entityID: entityID,
                openDateTime: openDate,
                closeDateTime: closeDate,
                minutesOpen: minutesOpen,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
    
    static func getTotalRecordCount() async throws -> Int {
        guard let url = URL(string: "\(baseURL)?$select=count(*)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstRecord = jsonArray.first,
           let countString = firstRecord["count"] as? String,
           let count = Int(countString) {
            return count
        }
        
        throw APIError.noData
    }
    
    static func importAllHistoricalData(
        batchSize: Int = 2000,
        progressCallback: @escaping (ImportProgress) -> Void
    ) async throws -> [DrawbridgeEvent] {
        
        // First, get total record count
        let totalRecords = try await getTotalRecordCount()
        let totalBatches = (totalRecords + batchSize - 1) / batchSize // Ceiling division
        
        var allEvents: [DrawbridgeEvent] = []
        var recordsImported = 0
        
        print("📊 Starting bulk import of \(totalRecords) records in \(totalBatches) batches")
        
        for batchIndex in 0..<totalBatches {
            let offset = batchIndex * batchSize
            
            // Update progress
            let progress = ImportProgress(
                totalRecords: totalRecords,
                currentBatch: batchIndex + 1,
                totalBatches: totalBatches,
                recordsImported: recordsImported,
                isComplete: false,
                currentBridge: nil
            )
            progressCallback(progress)
            
            // Fetch batch
            let batchEvents = try await fetchBatch(
                limit: batchSize,
                offset: offset
            )
            
            allEvents.append(contentsOf: batchEvents)
            recordsImported += batchEvents.count
            
            print("✅ Batch \(batchIndex + 1)/\(totalBatches): \(batchEvents.count) records imported")
            
            // Small delay to prevent API rate limiting
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Final progress update
        let finalProgress = ImportProgress(
            totalRecords: totalRecords,
            currentBatch: totalBatches,
            totalBatches: totalBatches,
            recordsImported: recordsImported,
            isComplete: true,
            currentBridge: nil
        )
        progressCallback(finalProgress)
        
        print("🎉 Bulk import complete: \(recordsImported) records imported")
        return allEvents
    }
    
    static func fetchBatch(limit: Int, offset: Int) async throws -> [DrawbridgeEvent] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$offset=\(offset)&$order=opendatetime DESC") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let responses = try JSONDecoder().decode([APIResponse].self, from: data)
        
        return responses.compactMap { response in
            guard let entityID = Int(response.entityid),
                  let openDate = DateFormatter.iso8601WithFractionalSeconds.date(from: response.opendatetime),
                  let minutesOpen = Double(response.minutesopen),
                  let latitude = Double(response.latitude),
                  let longitude = Double(response.longitude) else {
                return nil
            }
            
            let closeDate = response.closedatetime.flatMap { 
                DateFormatter.iso8601WithFractionalSeconds.date(from: $0) 
            }
            
            return DrawbridgeEvent(
                entityType: response.entitytype,
                entityName: response.entityname,
                entityID: entityID,
                openDateTime: openDate,
                closeDateTime: closeDate,
                minutesOpen: minutesOpen,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
    
    static func fetchDataInDateRange(
        startDate: Date,
        endDate: Date,
        limit: Int = 5000
    ) async throws -> [DrawbridgeEvent] {
        let dateFormatter = ISO8601DateFormatter()
        let startISO = dateFormatter.string(from: startDate)
        let endISO = dateFormatter.string(from: endDate)
        
        let query = "$where=opendatetime between '\(startISO)' and '\(endISO)'"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: "\(baseURL)?\(encodedQuery)&$limit=\(limit)&$order=opendatetime ASC") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let responses = try JSONDecoder().decode([APIResponse].self, from: data)
        
        return responses.compactMap { response in
            guard let entityID = Int(response.entityid),
                  let openDate = DateFormatter.iso8601WithFractionalSeconds.date(from: response.opendatetime),
                  let minutesOpen = Double(response.minutesopen),
                  let latitude = Double(response.latitude),
                  let longitude = Double(response.longitude) else {
                return nil
            }
            
            let closeDate = response.closedatetime?.isEmpty == false ? 
                DateFormatter.iso8601WithFractionalSeconds.date(from: response.closedatetime!) : nil
            
            return DrawbridgeEvent(
                entityType: response.entitytype,
                entityName: response.entityname,
                entityID: entityID,
                openDateTime: openDate,
                closeDateTime: closeDate,
                minutesOpen: minutesOpen,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case rateLimitExceeded
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .decodingError:
            return "Failed to decode API response"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        }
    }
}

extension DateFormatter {
    static let iso8601WithFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles") // Seattle time
        return formatter
    }()
}
