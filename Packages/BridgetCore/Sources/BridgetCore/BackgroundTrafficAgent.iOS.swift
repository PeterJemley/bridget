//
//  BackgroundTrafficAgent.iOS.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

#if os(iOS)

import Foundation
import CoreLocation
import BackgroundTasks
import Combine

// MARK: - iOS-Specific Background Traffic Agent

@MainActor
public class BackgroundTrafficAgent: BackgroundTrafficAgentProtocol {
    private let trafficService: TrafficAwareRoutingService
    private let motionService: MotionDetectionService
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
        setupNotifications()
        
        print("🚗 [Background] BackgroundTrafficAgent initialized")
    }
    
    deinit {
        // Clean up resources without calling actor-isolated methods
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
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
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
    }
    
    private func handleAppWillEnterForeground() {
        print("🚗 [Background] App will enter foreground")
        
        // Update monitoring status
        monitoringStatus = .active
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
        
        // Perform motion monitoring
        Task {
            await performBackgroundMotionCheck()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleUserEnteredVehicle() {
        print("🚗 [Background] User entered vehicle - starting enhanced monitoring")
        
        // Switch to enhanced monitoring mode
        monitoringStatus = .enhanced
        
        // Schedule more frequent background checks
        scheduleEnhancedBackgroundRefresh()
        
        // Add alert for vehicle entry
        let alert = TrafficAlert(
            type: .trafficWorsening,
            message: "Vehicle detected - enhanced monitoring active",
            severity: .medium
        )
        backgroundAlerts.append(alert)
    }
    
    private func handleUserExitedVehicle() {
        print("🚗 [Background] User exited vehicle - returning to normal monitoring")
        
        // Return to normal monitoring mode
        monitoringStatus = .active
        
        // Add alert for vehicle exit
        let alert = TrafficAlert(
            type: .trafficWorsening,
            message: "Vehicle exit detected - normal monitoring resumed",
            severity: .low
        )
        backgroundAlerts.append(alert)
    }
    
    private func scheduleEnhancedBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: trafficRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 minute for enhanced mode
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🚗 [Background] Enhanced background refresh scheduled")
        } catch {
            print("🚗 [Background] Failed to schedule enhanced background refresh: \(error)")
        }
    }
    
    private func performBackgroundTrafficCheck() async {
        print("🚗 [Background] Performing background traffic check...")
        
        // Simulate traffic check (replace with actual API call)
        await Task.sleep(1_000_000_000) // 1 second delay
        
        // Update last check time
        lastUpdateTime = Date()
        
        // Add sample alert (replace with actual traffic analysis)
        let alert = TrafficAlert(
            type: .trafficWorsening,
            message: "Background traffic check completed",
            severity: .low
        )
        backgroundAlerts.append(alert)
        
        print("🚗 [Background] Background traffic check completed")
    }
    
    private func performBackgroundMotionCheck() async {
        print("🚗 [Background] Performing background motion check...")
        
        // Simulate motion check (replace with actual motion analysis)
        await Task.sleep(500_000_000) // 0.5 second delay
        
        // Update last check time
        lastUpdateTime = Date()
        
        print("🚗 [Background] Background motion check completed")
    }
}

#endif 