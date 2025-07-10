#if os(iOS)
//  BackgroundTrafficAgent.iOS.swift
//  BridgetCore
//
//  iOS-only implementation of BackgroundTrafficAgent

import Foundation
import CoreLocation
import BackgroundTasks
import Combine
import UIKit

// MARK: - Background Traffic Agent

@MainActor
public class BackgroundTrafficAgent: ObservableObject {
    private let trafficService: TrafficAwareRoutingService
    private let motionService: MotionDetectionService
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var locationUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var isMonitoring = false
    @Published public var lastUpdateTime: Date?
    @Published public var backgroundAlerts: [TrafficAlert] = []
    @Published public var monitoringStatus: MonitoringStatus = .inactive
    
    // Background task identifiers
    private let trafficRefreshIdentifier = "com.bridget.traffic-refresh"
    private let motionMonitoringIdentifier = "com.bridget.motion-monitoring"
    
    public init(trafficService: TrafficAwareRoutingService, motionService: MotionDetectionService) {
        self.trafficService = trafficService
        self.motionService = motionService
        setupBackgroundTaskHandling()
        setupNotifications()
        
        print("🚗 [Background] BackgroundTrafficAgent initialized")
    }
    
    deinit {
        // Clean up resources without calling actor-isolated methods
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Starts background monitoring for traffic conditions and bridge events
    public func startBackgroundMonitoring() {
        guard !isMonitoring else {
            print("🚗 [Background] Already monitoring")
            return
        }
        
        print("🚗 [Background] Starting background monitoring...")
        
        // Register background tasks
        registerBackgroundTasks()
        
        // Start motion monitoring if not already active
        if !motionService.isMonitoring {
            motionService.startMonitoring()
        }
        
        // Start location monitoring
        startLocationMonitoring()
        
        // Start periodic traffic checks
        startTrafficCheckTimer()
        
        isMonitoring = true
        monitoringStatus = .active
        lastUpdateTime = Date()
        
        print("🚗 [Background] Background monitoring started")
    }
    
    /// Stops background monitoring and cleans up resources
    public func stopBackgroundMonitoring() {
        guard isMonitoring else { return }
        
        print("🚗 [Background] Stopping background monitoring...")
        
        // Stop timers
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        // End background task if active
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Stop motion monitoring
        motionService.stopMonitoring()
        
        isMonitoring = false
        monitoringStatus = .inactive
        
        print("🚗 [Background] Background monitoring stopped")
    }
    
    /// Clears all stored background alerts
    public func clearAlerts() {
        backgroundAlerts.removeAll()
        print("🚗 [Background] Cleared all background alerts")
    }
    
    /// Returns active alerts from the last hour
    public func getActiveAlerts() -> [TrafficAlert] {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return backgroundAlerts.filter { $0.timestamp > oneHourAgo }
    }
    
    // MARK: - Private Methods
    
    private func setupBackgroundTaskHandling() {
        // Register for background task notifications
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    private func setupNotifications() {
        // Listen for motion state changes
        NotificationCenter.default.publisher(for: .userEnteredVehicle)
            .sink { [weak self] _ in
                self?.handleUserEnteredVehicle()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userExitedVehicle)
            .sink { [weak self] _ in
                self?.handleUserExitedVehicle()
            }
            .store(in: &cancellables)
    }
    
    private func registerBackgroundTasks() {
        // Register traffic refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: trafficRefreshIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTrafficRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register motion monitoring task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: motionMonitoringIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundMotionMonitoring(task: task as! BGAppRefreshTask)
        }
        
        print("🚗 [Background] Background tasks registered")
    }
    
    private func startLocationMonitoring() {
        // Start location monitoring for bridge proximity
        // This will be implemented when we add CoreLocation integration
        print("🚗 [Background] Location monitoring ready (CoreLocation integration pending)")
    }
    
    private func startTrafficCheckTimer() {
        // Check traffic conditions every 5 minutes when in background
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.performBackgroundTrafficCheck()
            }
        }
        
        print("🚗 [Background] Traffic check timer started (5-minute intervals)")
    }
    
    private func handleAppDidEnterBackground() {
        print("🚗 [Background] App entered background")
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.handleBackgroundTaskExpiration()
        }
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
    }
    
    private func handleAppWillEnterForeground() {
        print("🚗 [Background] App will enter foreground")
        
        // End background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Update monitoring status
        monitoringStatus = .active
    }
    
    private func handleBackgroundTaskExpiration() {
        print("🚗 [Background] Background task expiring")
        
        // Clean up
        backgroundTask = .invalid
        monitoringStatus = .expired
        
        // Stop monitoring to conserve resources
        stopBackgroundMonitoring()
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: trafficRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 300) // 5 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🚗 [Background] Background refresh scheduled")
        } catch {
            print("🚗 [Background] Failed to schedule background refresh: \(error)")
        }
    }
    
    private func handleBackgroundTrafficRefresh(task: BGAppRefreshTask) {
        print("🚗 [Background] Background traffic refresh started")
        
        // Set up task expiration handler
        task.expirationHandler = {
            print("🚗 [Background] Background traffic refresh expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform traffic check
        Task {
            await performBackgroundTrafficCheck()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleBackgroundMotionMonitoring(task: BGAppRefreshTask) {
        print("🚗 [Background] Background motion monitoring started")
        
        // Set up task expiration handler
        task.expirationHandler = {
            print("🚗 [Background] Background motion monitoring expired")
            task.setTaskCompleted(success: false)
        }
        
        // Check motion state and generate alerts if needed
        Task {
            await performBackgroundMotionCheck()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func performBackgroundTrafficCheck() async {
        print("🚗 [Background] Performing background traffic check...")
        
        // Check current traffic conditions (they're already published properties)
        let currentConditions = trafficService.trafficConditions
        let currentRisk = trafficService.routeRiskLevel
        
        // Generate alerts for significant changes
        if currentConditions == .heavyTraffic {
            let alert = TrafficAlert(
                type: .trafficWorsening,
                message: "Heavy traffic detected on your route",
                severity: .high
            )
            await addAlert(alert)
        }
        
        if currentRisk == .high {
            let alert = TrafficAlert(
                type: .highRiskRoute,
                message: "High-risk route conditions detected",
                severity: .critical
            )
            await addAlert(alert)
        }
        
        lastUpdateTime = Date()
        print("🚗 [Background] Background traffic check completed")
    }
    
    private func performBackgroundMotionCheck() async {
        print("🚗 [Background] Performing background motion check...")
        
        // Check if user is in vehicle
        if motionService.vehicleState == .inVehicle {
            // Analyze traffic conditions based on motion
            let trafficCondition = motionService.analyzeTrafficConditions()
            
            if trafficCondition == .heavyTraffic {
                let alert = TrafficAlert(
                    type: .trafficWorsening,
                    message: "Motion sensors detect heavy traffic conditions",
                    severity: .medium
                )
                await addAlert(alert)
            }
        }
        
        print("🚗 [Background] Background motion check completed")
    }
    
    private func handleUserEnteredVehicle() {
        print("🚗 [Background] User entered vehicle")
        
        // Start enhanced monitoring
        monitoringStatus = .enhanced
        
        // Generate alert for vehicle entry
        let alert = TrafficAlert(
            type: .trafficModerate,
            message: "Vehicle detected - Enhanced monitoring active",
            severity: .low
        )
        
        Task {
            await addAlert(alert)
        }
    }
    
    private func handleUserExitedVehicle() {
        print("🚗 [Background] User exited vehicle")
        
        // Reduce monitoring intensity
        monitoringStatus = .active
        
        // Generate alert for vehicle exit
        let alert = TrafficAlert(
            type: .trafficImproving,
            message: "Vehicle exited - Standard monitoring active",
            severity: .low
        )
        
        Task {
            await addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: TrafficAlert) async {
        await MainActor.run {
            backgroundAlerts.append(alert)
            
            // Keep only last 50 alerts to prevent memory issues
            if backgroundAlerts.count > 50 {
                backgroundAlerts.removeFirst(backgroundAlerts.count - 50)
            }
            
            print("🚗 [Background] Alert added: \(alert.message)")
        }
    }
}

// MARK: - Supporting Types

public enum MonitoringStatus: String, CaseIterable {
    case inactive = "Inactive"
    case active = "Active"
    case enhanced = "Enhanced"
    case expired = "Expired"
    
    public var systemImage: String {
        switch self {
        case .inactive: return "circle.slash"
        case .active: return "circle.fill"
        case .enhanced: return "circle.fill"
        case .expired: return "exclamationmark.circle"
        }
    }
    
    public var color: String {
        switch self {
        case .inactive: return "gray"
        case .active: return "green"
        case .enhanced: return "blue"
        case .expired: return "orange"
        }
    }
}

public struct TrafficAlert: Identifiable, Codable {
    public let id: UUID
    public let type: TrafficAlertType
    public let message: String
    public let severity: AlertSeverity
    public let timestamp: Date
    
    public init(type: TrafficAlertType, message: String, severity: AlertSeverity) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.severity = severity
        self.timestamp = Date()
    }
}

public enum TrafficAlertType: String, CaseIterable, Codable {
    case trafficWorsening = "Traffic Worsening"
    case trafficImproving = "Traffic Improving"
    case trafficModerate = "Moderate Traffic"
    case highRiskRoute = "High Risk Route"
    case routeChange = "Route Change"
    case accidentAhead = "Accident Ahead"
}

public enum AlertSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var systemImage: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}
#endif 