//
//  Utilities.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation

// MARK: - Data Model Enums
public enum TimePeriod: CaseIterable {
    case twentyFourHours, sevenDays, thirtyDays, ninetyDays
    
    public var days: Int {
        switch self {
        case .twentyFourHours: return 1
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

public enum AnalysisType: CaseIterable {
    case patterns, cascade, predictions, impact
}

public enum ViewType: CaseIterable {
    case activity, weekly, duration
}

// MARK: - Chart Data Models
public struct HourlyData {
    public let hour: Int
    public let count: Int
    
    public init(hour: Int, count: Int) {
        self.hour = hour
        self.count = count
    }
}

public struct WeeklyData {
    public let dayIndex: Int
    public let dayName: String
    public let count: Int
    
    public init(dayIndex: Int, dayName: String, count: Int) {
        self.dayIndex = dayIndex
        self.dayName = dayName
        self.count = count
    }
}

/// Centralized security logging utility that prevents sensitive data exposure in production
public enum SecurityLogger {
    
    /// Debug logging - only outputs in DEBUG builds
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[DEBUG] \(message) - \(fileName):\(line)")
        #endif
    }
    
    /// Error logging - always logs but sanitizes sensitive data
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    public static func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let sanitizedMessage = sanitizeForLogging(message)
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[ERROR] \(sanitizedMessage) - \(fileName):\(line)")
        
        if let error = error {
            let sanitizedError = sanitizeForLogging(error.localizedDescription)
            print("[ERROR] Details: \(sanitizedError)")
        }
    }
    
    /// Performance logging - only outputs in DEBUG builds
    /// - Parameters:
    ///   - operation: Operation name
    ///   - duration: Duration in seconds
    public static func performance(_ operation: String, duration: TimeInterval) {
        #if DEBUG
        print("[PERF] \(operation): \(String(format: "%.3f", duration))s")
        #endif
    }
    
    /// API logging - sanitizes URLs and sensitive data
    /// - Parameters:
    ///   - message: The message to log
    ///   - url: Optional URL to sanitize
    public static func api(_ message: String, url: URL? = nil) {
        #if DEBUG
        var sanitizedMessage = sanitizeForLogging(message)
        if let url = url {
            sanitizedMessage += " - URL: [API_ENDPOINT]"
        }
        print("[API] \(sanitizedMessage)")
        #endif
    }
    
    /// Motion detection logging - sanitizes location data
    /// - Parameter message: The message to log
    public static func motion(_ message: String) {
        #if DEBUG
        let sanitizedMessage = sanitizeForLogging(message)
        print("[MOTION] \(sanitizedMessage)")
        #endif
    }
    
    /// Neural engine logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func neural(_ message: String) {
        #if DEBUG
        print("[NEURAL] \(message)")
        #endif
    }
    
    /// Statistics logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func stats(_ message: String) {
        #if DEBUG
        print("[STATS] \(message)")
        #endif
    }
    
    /// Cascade detection logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func cascade(_ message: String) {
        #if DEBUG
        print("[CASCADE] \(message)")
        #endif
    }
    
    /// Bridge detail logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func bridge(_ message: String) {
        #if DEBUG
        print("[BRIDGE] \(message)")
        #endif
    }
    
    /// Main app logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func main(_ message: String) {
        #if DEBUG
        print("[MAIN] \(message)")
        #endif
    }
    
    /// Sync logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func sync(_ message: String) {
        #if DEBUG
        print("[SYNC] \(message)")
        #endif
    }
    
    /// Test logging - only outputs in DEBUG builds
    /// - Parameter message: The message to log
    public static func test(_ message: String) {
        #if DEBUG
        print("[TEST] \(message)")
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Sanitizes sensitive data from log messages
    /// - Parameter message: The message to sanitize
    /// - Returns: Sanitized message with sensitive data removed
    private static func sanitizeForLogging(_ message: String) -> String {
        var sanitized = message
        
        // Remove URLs
        sanitized = sanitized.replacingOccurrences(of: #"https?://[^\s]+"#, with: "[URL]", options: .regularExpression)
        
        // Remove coordinates (latitude/longitude patterns)
        sanitized = sanitized.replacingOccurrences(of: #"[-+]?[0-9]*\.?[0-9]+"#, with: "[COORD]", options: .regularExpression)
        
        // Remove API keys or tokens
        sanitized = sanitized.replacingOccurrences(of: #"[a-zA-Z0-9]{32,}"#, with: "[TOKEN]", options: .regularExpression)
        
        // Remove device identifiers
        sanitized = sanitized.replacingOccurrences(of: #"[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}"#, with: "[UUID]", options: .regularExpression)
        
        return sanitized
    }
}
