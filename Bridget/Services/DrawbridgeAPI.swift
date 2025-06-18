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
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
}

extension DateFormatter {
    static let iso8601WithFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles") // Seattle time
        return formatter
    }()
}