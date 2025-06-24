//
//  AppSettings.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/23/25.
//

import Foundation
import SwiftUI

/// Centralized app settings manager using UserDefaults
public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private init() {}
    
    // MARK: - General Settings
    
    @AppStorage("autoRefreshEnabled") public var autoRefreshEnabled: Bool = true
    @AppStorage("refreshIntervalMinutes") public var refreshIntervalMinutes: Int = 60
    @AppStorage("preferredTimeFormat") public var preferredTimeFormat: String = "12h"
    @AppStorage("compactMode") public var compactMode: Bool = false
    
    // MARK: - Data & Privacy Settings
    
    @AppStorage("dataRetentionDays") public var dataRetentionDays: Int = 30
    @AppStorage("analyticsEnabled") public var analyticsEnabled: Bool = true
    
    // MARK: - Notification Settings
    
    @AppStorage("notificationsEnabled") public var notificationsEnabled: Bool = false
    
    // MARK: - Developer Settings
    
    @AppStorage("showGeekFeatures") public var showGeekFeatures: Bool = false
    
    // MARK: - Computed Properties
    
    public var is24HourFormat: Bool {
        return preferredTimeFormat == "24h"
    }
    
    public var refreshIntervalTimeInterval: TimeInterval {
        return TimeInterval(refreshIntervalMinutes * 60)
    }
    
    public var dataRetentionDate: Date? {
        guard dataRetentionDays > 0 else { return nil } // Forever
        return Calendar.current.date(byAdding: .day, value: -dataRetentionDays, to: Date())
    }
    
    // MARK: - Formatting Helpers
    
    public func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    public func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if is24HourFormat {
            formatter.dateFormat = "MMM d, HH:mm"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: date)
    }
    
    // MARK: - Enhanced Event Formatting
    
    public func formatEventTime(_ event: DrawbridgeEvent) -> String {
        return formatTime(event.openDateTime)
    }
    
    public func formatEventDateTime(_ event: DrawbridgeEvent) -> String {
        return formatDateTime(event.openDateTime)
    }
    
    // MARK: - UI Helpers
    
    public var primaryFont: Font {
        return compactMode ? .caption : .body
    }
    
    public var headlineFont: Font {
        return compactMode ? .subheadline : .headline
    }
    
    public var titleFont: Font {
        return compactMode ? .headline : .title2
    }
    
    public var cardPadding: CGFloat {
        return compactMode ? 12 : 16
    }
    
    public var verticalSpacing: CGFloat {
        return compactMode ? 8 : 12
    }
    
    public var sectionSpacing: CGFloat {
        return compactMode ? 16 : 20
    }
    
    // MARK: - Data Management
    
    public func shouldRetainEvent(_ event: DrawbridgeEvent) -> Bool {
        guard let retentionDate = dataRetentionDate else { return true } // Forever
        return event.openDateTime >= retentionDate
    }
    
    public func filterEventsByRetention(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        return DrawbridgeEvent.filterByRetentionDate(events, retentionDate: dataRetentionDate)
    }
    
    public func shouldAutoRefresh(lastRefresh: Date?) -> Bool {
        guard autoRefreshEnabled else { return false }
        guard let lastRefresh = lastRefresh else { return true }
        
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
        return timeSinceLastRefresh >= refreshIntervalTimeInterval
    }
}

// MARK: - SwiftUI Environment Key

public struct AppSettingsKey: EnvironmentKey {
    public static let defaultValue = AppSettings.shared
}

public extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}