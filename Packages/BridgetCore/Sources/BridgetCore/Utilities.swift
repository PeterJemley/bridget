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