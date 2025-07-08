# Bridget Background Agents Documentation

## Overview

The Bridget Background Agents system provides intelligent, real-time traffic monitoring capabilities that continue to operate even when the app is in the background. This system is designed to help users navigate traffic efficiently by providing proactive alerts and route optimization suggestions.

## Architecture

### Core Components

1. **BackgroundTrafficAgent** - Main agent class that manages background monitoring
2. **TrafficAwareRoutingService** - Existing service that provides traffic analysis
3. **TrafficAlert** - Data structure for traffic-related notifications
4. **BackgroundTaskHandler** - Manages iOS background task execution

### System Flow

```
User Sets Route → Background Agent Starts → Continuous Monitoring → Alert Generation → User Notification
```

## Implementation Details

### BackgroundTrafficAgent Class

The main agent class that orchestrates background monitoring:

```swift
@MainActor
public class BackgroundTrafficAgent: ObservableObject {
    private let trafficService: TrafficAwareRoutingService
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var locationUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var isMonitoring = false
    @Published public var lastUpdateTime: Date?
    @Published public var backgroundAlerts: [TrafficAlert] = []
}
```

#### Key Methods

- `startBackgroundMonitoring()` - Initiates background monitoring
- `stopBackgroundMonitoring()` - Stops monitoring and cleans up resources
- `performBackgroundTrafficCheck()` - Executes traffic analysis in background
- `handleTrafficConditionChange()` - Responds to traffic condition changes
- `handleRiskLevelChange()` - Responds to risk level changes

### TrafficAlert System

The alert system provides structured notifications for different traffic scenarios:

```swift
public struct TrafficAlert: Identifiable, Codable {
    public let id: UUID
    public let type: TrafficAlertType
    public let message: String
    public let severity: AlertSeverity
    public let timestamp: Date
}
```

#### Alert Types

| Type | Description | Use Case |
|------|-------------|----------|
| `trafficWorsening` | Traffic conditions deteriorating | Heavy congestion detected |
| `trafficImproving` | Traffic conditions improving | Congestion clearing |
| `trafficModerate` | Moderate traffic detected | Normal traffic flow |
| `highRiskRoute` | High-risk route identified | Dangerous conditions |
| `routeChange` | Route change recommended | Better alternative available |
| `accidentAhead` | Accident reported ahead | Immediate hazard |

#### Severity Levels

| Level | Color | Description |
|-------|-------|-------------|
| `low` | Green | Minor issues, informational |
| `medium` | Yellow | Moderate concerns |
| `high` | Orange | Significant problems |
| `critical` | Red | Severe issues requiring attention |

## Integration Guide

### 1. Basic Setup

```swift
import BridgetCore

class YourViewModel: ObservableObject {
    @Published var trafficService = TrafficAwareRoutingService()
    @Published var backgroundAgent: BackgroundTrafficAgent
    
    init() {
        self.backgroundAgent = BackgroundTrafficAgent(trafficService: trafficService)
        setupAlertHandling()
    }
    
    private func setupAlertHandling() {
        backgroundAgent.$backgroundAlerts
            .sink { [weak self] alerts in
                self?.handleNewAlerts(alerts)
            }
            .store(in: &cancellables)
    }
}
```

### 2. Route Configuration

```swift
func configureRoute(start: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
    // Set route in traffic service
    trafficService.calculateRoute(from: start, to: destination)
    
    // Start background monitoring
    backgroundAgent.startBackgroundMonitoring()
}
```

### 3. Alert Handling

```swift
private func handleNewAlerts(_ alerts: [TrafficAlert]) {
    for alert in alerts {
        switch alert.severity {
        case .critical:
            showCriticalAlert(alert)
        case .high:
            showHighPriorityAlert(alert)
        case .medium:
            showMediumPriorityAlert(alert)
        case .low:
            showLowPriorityAlert(alert)
        }
    }
}
```

## Background Task Configuration

### iOS Background Processing Setup

#### AppDelegate Configuration

```swift
import BackgroundTasks

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Register background task
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.bridget.traffic-refresh",
        using: nil
    ) { task in
        BackgroundTaskHandler.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
    }
    
    return true
}
```

#### Info.plist Requirements

Add the following entries to your Info.plist:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-app-refresh</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.bridget.traffic-refresh</string>
</array>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Bridget needs location access to monitor traffic conditions on your route.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Bridget needs location access to provide background traffic monitoring.</string>
```

## SwiftUI Integration Example

### Complete View Implementation

```swift
struct TrafficMonitoringView: View {
    @StateObject private var viewModel = BackgroundAgentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                MonitoringStatusView(viewModel: viewModel)
                
                // Traffic Information
                TrafficInfoView(viewModel: viewModel)
                
                // Alerts Section
                AlertsSectionView(viewModel: viewModel)
                
                // Control Buttons
                ControlButtonsView(viewModel: viewModel)
            }
            .padding()
            .navigationTitle("Traffic Monitor")
        }
    }
}

struct MonitoringStatusView: View {
    @ObservedObject var viewModel: BackgroundAgentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monitoring Status")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(viewModel.isMonitoring ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(viewModel.isMonitoring ? "Active" : "Inactive")
                    .font(.subheadline)
            }
            
            if let lastUpdate = viewModel.backgroundAgent.lastUpdateTime {
                Text("Last Update: \(lastUpdate, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
```

## Best Practices

### 1. Battery Optimization

- Use efficient background processing intervals (5-15 minutes)
- Implement proper task completion handling
- Avoid unnecessary location updates in background

### 2. Memory Management

- Clear old alerts periodically
- Use weak references in closures
- Properly dispose of Combine subscriptions

### 3. Error Handling

```swift
private func handleBackgroundTaskError(_ error: Error) {
    print("Background task error: \(error)")
    // Implement retry logic or user notification
}
```

### 4. User Experience

- Provide clear status indicators
- Show meaningful alert messages
- Allow users to control monitoring preferences

## Testing Strategy

### 1. Device Testing

Background agents must be tested on physical devices:

```swift
#if DEBUG
func simulateBackgroundRefresh() {
    // Simulate background task execution
    BackgroundTaskHandler.handleBackgroundRefresh(task: mockTask)
}
#endif
```

### 2. Alert Testing

```swift
func testAlertGeneration() {
    let agent = BackgroundTrafficAgent(trafficService: mockTrafficService)
    
    // Simulate traffic condition change
    agent.handleTrafficConditionChange(.heavy)
    
    // Verify alert generation
    XCTAssertFalse(agent.backgroundAlerts.isEmpty)
}
```

### 3. Background Task Testing

```swift
func testBackgroundTaskRegistration() {
    let expectation = XCTestExpectation(description: "Background task registered")
    
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "test-task") { task in
        expectation.fulfill()
        task.setTaskCompleted(success: true)
    }
    
    wait(for: [expectation], timeout: 5.0)
}
```

## Performance Considerations

### 1. Background Execution Limits

- iOS limits background execution time (typically 30 seconds)
- Implement efficient processing algorithms
- Use background task expiration handlers

### 2. Network Usage

- Minimize API calls in background
- Cache traffic data when possible
- Use efficient data formats

### 3. Location Services

- Request appropriate location permissions
- Use significant location changes when possible
- Implement location accuracy optimization

## Troubleshooting

### Common Issues

1. **Background tasks not executing**
   - Verify Info.plist configuration
   - Check background app refresh settings
   - Ensure proper task registration

2. **Alerts not appearing**
   - Verify Combine subscription setup
   - Check alert filtering logic
   - Ensure UI updates on main thread

3. **Battery drain**
   - Review background processing intervals
   - Check for memory leaks
   - Optimize location update frequency

### Debug Logging

```swift
#if DEBUG
private func logBackgroundActivity(_ message: String) {
    print("[BackgroundAgent] \(Date()): \(message)")
}
#endif
```

## Future Enhancements

### Planned Features

1. **Machine Learning Integration**
   - Predictive traffic modeling
   - Personalized route recommendations
   - Historical pattern analysis

2. **Advanced Alerting**
   - Geofence-based alerts
   - Time-based notifications
   - Custom alert preferences

3. **Multi-modal Support**
   - Public transit integration
   - Walking route optimization
   - Bicycle route suggestions

## API Reference

### BackgroundTrafficAgent

| Method | Description | Parameters |
|--------|-------------|------------|
| `startBackgroundMonitoring()` | Starts background monitoring | None |
| `stopBackgroundMonitoring()` | Stops background monitoring | None |
| `clearAlerts()` | Clears all stored alerts | None |
| `getActiveAlerts()` | Returns active alerts from last hour | None |

### TrafficAlert

| Property | Type | Description |
|----------|------|-------------|
| `id` | UUID | Unique identifier |
| `type` | TrafficAlertType | Type of alert |
| `message` | String | Human-readable message |
| `severity` | AlertSeverity | Alert importance level |
| `timestamp` | Date | When alert was generated |

## Implementation Files

The background agents implementation is located in:

```
Packages/BridgetCore/Sources/BridgetCore/
├── BackgroundTrafficAgent.swift      # Main background agent class
├── BackgroundAgentExample.swift      # SwiftUI example implementation
└── TrafficAwareRoutingService.swift  # Existing traffic service
```

## License

This background agents implementation is part of the Bridget project and follows the same licensing terms as the main application.

---

*For questions or issues with the background agents implementation, please refer to the main Bridget documentation or contact the development team.*
