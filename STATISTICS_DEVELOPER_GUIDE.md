# Bridget Statistics Developer Guide

## Overview

This guide provides technical details for developers working with Bridget's Statistics module, including API usage, data models, integration patterns, and extension points.

## Architecture Overview

```
RoutingView (UI Layer)
    ↓
TrafficAwareRoutingService (Business Logic)
    ↓
MotionDetectionService (Traffic Sensing)
    ↓
Apple Maps API (Live Traffic Data)
```

## Core Data Models

### BridgeAnalytics

The primary analytics model for statistical calculations:

```swift
@Model
public final class BridgeAnalytics {
    @Attribute(.unique) public var id: String
    public var entityID: Int
    public var entityName: String
    
    // Temporal dimensions
    public var year: Int
    public var month: Int
    public var dayOfWeek: Int
    public var hour: Int
    
    // Statistical metrics
    public var openingCount: Int = 0
    public var totalMinutesOpen: Double = 0
    public var averageMinutesPerOpening: Double = 0
    public var longestOpeningMinutes: Double = 0
    public var shortestOpeningMinutes: Double = 0
    
    // Prediction factors
    public var probabilityOfOpening: Double = 0
    public var expectedDuration: Double = 0
    public var confidence: Double = 0
    
    public var lastCalculated: Date
}
```

**Usage Example:**
```swift
// Create analytics for a specific time slot
let analytics = BridgeAnalytics(
    entityID: 1,
    entityName: "Fremont Bridge",
    year: 2025,
    month: 1,
    dayOfWeek: 2, // Monday
    hour: 8 // 8 AM
)

// Update with event data
analytics.openingCount += 1
analytics.totalMinutesOpen += event.minutesOpen
analytics.averageMinutesPerOpening = analytics.totalMinutesOpen / Double(analytics.openingCount)
```

### CascadeEvent

Represents traffic chain reactions between bridges:

```swift
@Model
public final class CascadeEvent {
    @Attribute(.unique) public var id: String
    
    // Trigger bridge (causes the cascade)
    public var triggerBridgeID: Int
    public var triggerBridgeName: String
    public var triggerTime: Date
    public var triggerDuration: Double
    
    // Target bridge (affected by the cascade)
    public var targetBridgeID: Int
    public var targetBridgeName: String
    public var targetTime: Date
    public var targetDuration: Double
    
    // Cascade characteristics
    public var cascadeStrength: Double // 0.0 to 1.0
    public var cascadeType: String // "immediate", "delayed", "weak"
    public var delayMinutes: Double
}
```

**Usage Example:**
```swift
let cascade = CascadeEvent(
    triggerBridgeID: 1,
    triggerBridgeName: "Fremont Bridge",
    targetBridgeID: 2,
    targetBridgeName: "Ballard Bridge",
    triggerTime: Date(),
    targetTime: Date().addingTimeInterval(1800), // 30 minutes later
    cascadeStrength: 0.75,
    cascadeType: "delayed",
    delayMinutes: 30.0
)
```

## API Usage

### BridgeAnalyticsCalculator

Primary interface for calculating analytics from raw events:

```swift
// Thread-safe calculation with DTOs
let eventDTOs = events.map { EventDTO(from: $0) }
let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: eventDTOs)

// Legacy calculation with model objects
let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
```

**Key Features:**
- **Thread Safety**: Uses DTOs for cross-thread data transfer
- **Background Processing**: Automatically runs on background threads
- **Cascade Detection**: Triggers cascade analysis in background
- **Progress Tracking**: Provides progress updates for large datasets

### NeuralEngineARIMAPredictor

AI-powered prediction engine with hardware optimization:

```swift
let predictor = NeuralEngineARIMAPredictor()
let predictions = predictor.generatePredictions(
    from: events,
    existingAnalytics: analytics
)

for prediction in predictions {
    print("Bridge: \(prediction.entityName)")
    print("Probability: \(prediction.probability)")
    print("Duration: \(prediction.expectedDuration)")
    print("Confidence: \(prediction.confidence)")
    print("Neural Engine: \(prediction.neuralGeneration)")
}
```

**Hardware Detection:**
```swift
let config = NeuralEngineManager.getOptimalConfig()
print("Generation: \(config.generation.rawValue)")
print("Cores: \(config.generation.coreCount)")
print("TOPS: \(config.generation.topsCapability)")
print("Complexity: \(config.complexity.rawValue)")
```

### CascadeDetectionEngine

Advanced cascade detection using spatial and temporal analysis:

```swift
let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: events)

for cascade in cascadeEvents {
    print("Trigger: \(cascade.triggerBridgeName)")
    print("Target: \(cascade.targetBridgeName)")
    print("Strength: \(cascade.cascadeStrength)")
    print("Delay: \(cascade.delayMinutes) minutes")
}
```

## Integration Patterns

### SwiftData Integration

```swift
@MainActor
class StatisticsViewModel: ObservableObject {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var analytics: [BridgeAnalytics]
    @Query private var cascadeEvents: [CascadeEvent]
    
    func refreshAnalytics() async {
        let eventDTOs = events.map { EventDTO(from: $0) }
        
        await Task.detached(priority: .userInitiated) {
            let newAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: eventDTOs)
            
            await MainActor.run {
                // Update SwiftData on main thread
                for existing in self.analytics {
                    self.modelContext.delete(existing)
                }
                
                for analytic in newAnalytics {
                    self.modelContext.insert(analytic)
                }
                
                try? self.modelContext.save()
            }
        }.value
    }
}
```

### Background Processing

```swift
func performHeavyCalculation() async throws -> AnalysisResult {
    return try await Task.detached(priority: .userInitiated) {
        // Perform heavy computation on background thread
        let result = self.computeComplexAnalysis()
        return result
    }.value
}
```

### Error Handling

```swift
enum StatisticsError: Error, LocalizedError {
    case insufficientData
    case calculationFailed(String)
    case neuralEngineUnavailable
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Insufficient data for analysis"
        case .calculationFailed(let reason):
            return "Calculation failed: \(reason)"
        case .neuralEngineUnavailable:
            return "Neural Engine not available on this device"
        }
    }
}

func safeCalculation() async throws {
    guard !events.isEmpty else {
        throw StatisticsError.insufficientData
    }
    
    do {
        let result = try await performHeavyCalculation()
        // Handle success
    } catch {
        throw StatisticsError.calculationFailed(error.localizedDescription)
    }
}
```

## Extension Points

### Custom Prediction Models

Create custom prediction models by implementing the prediction interface:

```swift
protocol BridgePredictionModel {
    func generatePredictions(
        from events: [DrawbridgeEvent],
        existingAnalytics: [BridgeAnalytics]
    ) -> [BridgePrediction]
}

class CustomPredictionModel: BridgePredictionModel {
    func generatePredictions(
        from events: [DrawbridgeEvent],
        existingAnalytics: [BridgeAnalytics]
    ) -> [BridgePrediction] {
        // Implement custom prediction logic
        return []
    }
}
```

### Custom Cascade Detection

Extend cascade detection with custom algorithms:

```swift
protocol CascadeDetectionAlgorithm {
    func detectCascades(from events: [DrawbridgeEvent]) -> [CascadeEvent]
}

class CustomCascadeDetector: CascadeDetectionAlgorithm {
    func detectCascades(from events: [DrawbridgeEvent]) -> [CascadeEvent] {
        // Implement custom cascade detection
        return []
    }
}
```

### Custom Analytics Metrics

Add new statistical metrics to the analytics model:

```swift
extension BridgeAnalytics {
    // Custom computed properties
    var openingFrequency: Double {
        return Double(openingCount) / 24.0 // openings per day
    }
    
    var averageDailyOpenings: Double {
        return Double(openingCount) / 30.0 // assuming monthly data
    }
    
    // Custom calculation methods
    func calculatePeakHourProbability() -> Double {
        // Custom peak hour analysis
        return 0.0
    }
}
```

## Performance Optimization

### Caching Strategy

```swift
class StatisticsCache {
    private var cache: [String: Any] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    func getCachedValue<T>(for key: String) -> T? {
        guard let entry = cache[key] as? CacheEntry<T>,
              Date().timeIntervalSince(entry.timestamp) < cacheTimeout else {
            return nil
        }
        return entry.value
    }
    
    func setCachedValue<T>(_ value: T, for key: String) {
        cache[key] = CacheEntry(value: value, timestamp: Date())
    }
}

struct CacheEntry<T> {
    let value: T
    let timestamp: Date
}
```

### Memory Management

```swift
class MemoryOptimizedCalculator {
    private let maxEventCount = 1000
    private let batchSize = 100
    
    func processLargeDataset(_ events: [DrawbridgeEvent]) -> [BridgeAnalytics] {
        let limitedEvents = Array(events.suffix(maxEventCount))
        var results: [BridgeAnalytics] = []
        
        for batch in limitedEvents.chunked(into: batchSize) {
            autoreleasepool {
                let batchResults = processBatch(batch)
                results.append(contentsOf: batchResults)
            }
        }
        
        return results
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

## Testing

### Unit Tests

```swift
class StatisticsTests: XCTestCase {
    var testEvents: [DrawbridgeEvent] = []
    
    override func setUp() {
        super.setUp()
        testEvents = createTestEvents()
    }
    
    func testAnalyticsCalculation() throws {
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        XCTAssertFalse(analytics.isEmpty)
        
        for analytic in analytics {
            XCTAssertTrue(analytic.openingCount >= 0)
            XCTAssertTrue(analytic.probabilityOfOpening >= 0.0 && analytic.probabilityOfOpening <= 1.0)
            XCTAssertTrue(analytic.confidence >= 0.0 && analytic.confidence <= 1.0)
        }
    }
    
    func testNeuralEnginePrediction() throws {
        let predictor = NeuralEngineARIMAPredictor()
        let predictions = predictor.generatePredictions(from: testEvents)
        
        for prediction in predictions {
            XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0)
            XCTAssertTrue(prediction.expectedDuration > 0)
            XCTAssertFalse(prediction.reasoning.isEmpty)
        }
    }
    
    func testCascadeDetection() throws {
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: testEvents)
        
        for cascade in cascades {
            XCTAssertTrue(cascade.triggerBridgeID > 0)
            XCTAssertTrue(cascade.targetBridgeID > 0)
            XCTAssertNotEqual(cascade.triggerBridgeID, cascade.targetBridgeID)
            XCTAssertTrue(cascade.cascadeStrength >= 0.0 && cascade.cascadeStrength <= 1.0)
        }
    }
}
```

### Performance Tests

```swift
func testLargeDatasetPerformance() throws {
    let largeDataset = createLargeTestDataset(count: 2000)
    
    measure {
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: largeDataset)
        XCTAssertFalse(analytics.isEmpty)
    }
}

func testMemoryUsage() throws {
    let largeDataset = createLargeTestDataset(count: 5000)
    
    let initialMemory = getMemoryUsage()
    
    autoreleasepool {
        let _ = BridgeAnalyticsCalculator.calculateAnalytics(from: largeDataset)
    }
    
    let finalMemory = getMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory
    
    // Memory increase should be reasonable (less than 50MB)
    XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024)
}
```

### Integration Tests

```swift
class StatisticsIntegrationTests: XCTestCase {
    func testEndToEndStatisticsFlow() async throws {
        let events = createRealisticTestEvents()
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        let predictor = NeuralEngineARIMAPredictor()
        let predictions = predictor.generatePredictions(from: events, existingAnalytics: analytics)
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: events)
        
        // Verify all components work together
        XCTAssertFalse(analytics.isEmpty)
        XCTAssertFalse(predictions.isEmpty)
        XCTAssertTrue(cascades.count >= 0)
        
        // Verify data consistency
        for prediction in predictions {
            let matchingAnalytics = analytics.first { $0.entityID == prediction.entityID }
            XCTAssertNotNil(matchingAnalytics)
        }
    }
}
```

## Debugging

### Logging

```swift
enum StatisticsLog {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        print("[STATS] \(message) - \(file):\(line)")
        #endif
    }
    
    static func error(_ message: String, error: Error? = nil) {
        print("[STATS ERROR] \(message)")
        if let error = error {
            print("[STATS ERROR] Details: \(error)")
        }
    }
    
    static func performance(_ operation: String, duration: TimeInterval) {
        print("[STATS PERF] \(operation): \(String(format: "%.3f", duration))s")
    }
}
```

### Performance Monitoring

```swift
class PerformanceMonitor {
    private var startTimes: [String: Date] = [:]
    
    func startOperation(_ name: String) {
        startTimes[name] = Date()
    }
    
    func endOperation(_ name: String) {
        guard let startTime = startTimes[name] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        StatisticsLog.performance(name, duration: duration)
        startTimes.removeValue(forKey: name)
    }
}
```

## Best Practices

### Thread Safety

1. **Always use DTOs** for cross-thread data transfer
2. **Perform heavy calculations** on background threads
3. **Update UI** only on the main thread
4. **Use proper synchronization** for shared resources

### Memory Management

1. **Limit dataset sizes** for large operations
2. **Use autoreleasepool** for batch processing
3. **Cache results** to avoid redundant calculations
4. **Monitor memory usage** in performance-critical operations

### Error Handling

1. **Validate input data** before processing
2. **Provide meaningful error messages**
3. **Handle edge cases** gracefully
4. **Log errors** for debugging

### Performance

1. **Profile operations** to identify bottlenecks
2. **Use appropriate thread priorities**
3. **Optimize algorithms** for your use case
4. **Test with realistic data sizes**

## Summary

The Bridget Statistics module provides a robust foundation for AI-powered bridge analytics. By following the patterns and best practices outlined in this guide, developers can effectively integrate, extend, and maintain the statistics functionality while ensuring optimal performance and reliability.

Key takeaways:
- Use the provided APIs for thread-safe operations
- Leverage hardware-specific optimizations
- Implement proper error handling and logging
- Test thoroughly with realistic datasets
- Monitor performance and memory usage
- Follow SwiftData best practices for persistence

## Integration Patterns

```swift
// Integrate RoutingView in main TabView
TabView {
    // ... other tabs ...
    RoutingView()
        .tabItem {
            Image(systemName: "car.fill")
            Text("Routes")
        }
}
```

- Use `TrafficAwareRoutingService` for route planning and traffic analysis
- Use `MotionDetectionService` for real-time traffic sensing and context 