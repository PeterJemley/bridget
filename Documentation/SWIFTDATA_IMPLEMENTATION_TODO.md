# SwiftData Implementation TODO List

## Branch: `swiftdata-implementation-review`

### High Priority Tasks

#### 1. Clean Up Unused Models
- [ ] **Remove ARIMAModel from backup file**
  - File: `Packages/BridgetCore/Sources/BridgetCore/ARIMAPredictionEngine.swift.backup`
  - Action: Delete or comment out the @Model class
  - Impact: Reduces schema confusion

- [ ] **Remove TimeSeriesPoint from backup file**
  - File: `Packages/BridgetCore/Sources/BridgetCore/ARIMAPredictionEngine.swift.backup`
  - Action: Delete or comment out the @Model class
  - Impact: Reduces schema confusion

- [ ] **Verify schema consistency**
  - File: `Bridget/BridgetApp.swift`
  - Action: Ensure schema only includes active models
  - Impact: Prevents runtime errors

#### 2. Add @Query Predicates for Performance

- [ ] **Optimize StatisticsView queries**
  - File: `Packages/BridgetStatistics/Sources/BridgetStatistics/StatisticsView.swift`
  - Current: `@Query private var events: [DrawbridgeEvent]`
  - Target: Add time-based filtering
  - Code:
    ```swift
    @Query(filter: #Predicate<DrawbridgeEvent> { event in
        event.openDateTime >= Calendar.current.date(byAdding: .day, value: -90, to: Date())!
    }, sort: \DrawbridgeEvent.openDateTime, order: .reverse) 
    private var events: [DrawbridgeEvent]
    ```

- [ ] **Optimize ContentViewModular queries**
  - File: `Bridget/ContentViewModular.swift`
  - Current: `@Query private var allEvents: [DrawbridgeEvent]`
  - Target: Add recent events filtering
  - Code:
    ```swift
    @Query(filter: #Predicate<DrawbridgeEvent> { event in
        event.openDateTime >= Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    }, sort: \DrawbridgeEvent.openDateTime, order: .reverse) 
    private var allEvents: [DrawbridgeEvent]
    ```

- [ ] **Optimize BridgeDetailView queries**
  - File: `Packages/BridgetBridgeDetail/Sources/BridgetBridgeDetail/BridgeDetailView.swift`
  - Current: `@Query private var allEvents: [DrawbridgeEvent]`
  - Target: Add bridge-specific filtering
  - Code:
    ```swift
    @Query(filter: #Predicate<DrawbridgeEvent> { event in
        event.entityID == bridgeEvent.entityID
    }, sort: \DrawbridgeEvent.openDateTime, order: .reverse) 
    private var allEvents: [DrawbridgeEvent]
    ```

- [ ] **Optimize DebugView queries**
  - File: `Packages/BridgetSettings/Sources/BridgetSettings/DebugView.swift`
  - Current: `@Query private var events: [DrawbridgeEvent]`
  - Target: Add recent events filtering
  - Code:
    ```swift
    @Query(filter: #Predicate<DrawbridgeEvent> { event in
        event.openDateTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }, sort: \DrawbridgeEvent.openDateTime, order: .reverse) 
    private var events: [DrawbridgeEvent]
    ```

#### 3. Implement @Bindable for Automatic Saves

- [ ] **Add @Bindable to DrawbridgeEvent**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeEvent.swift`
  - Action: Add @Bindable attribute
  - Code:
    ```swift
    @Model
    @Bindable
    public final class DrawbridgeEvent {
        // ... existing properties
    }
    ```

- [ ] **Add @Bindable to DrawbridgeInfo**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeInfo.swift`
  - Action: Add @Bindable attribute
  - Code:
    ```swift
    @Model
    @Bindable
    public final class DrawbridgeInfo {
        // ... existing properties
    }
    ```

- [ ] **Add @Bindable to BridgeAnalytics**
  - File: `Packages/BridgetCore/Sources/BridgetCore/BridgeAnalytics.swift`
  - Action: Add @Bindable attribute
  - Code:
    ```swift
    @Model
    @Bindable
    public final class BridgeAnalytics {
        // ... existing properties
    }
    ```

- [ ] **Add @Bindable to CascadeEvent**
  - File: `Packages/BridgetCore/Sources/BridgetCore/BridgeAnalytics.swift`
  - Action: Add @Bindable attribute
  - Code:
    ```swift
    @Model
    @Bindable
    public final class CascadeEvent {
        // ... existing properties
    }
    ```

### Medium Priority Tasks

#### 4. Add Batch Operations

- [ ] **Optimize clearAllDrawbridgeEvents function**
  - File: `Bridget/ContentViewModular.swift`
  - Current: Loop-based deletion
  - Target: Batch deletion
  - Code:
    ```swift
    private func clearAllDrawbridgeEvents() {
        let descriptor = FetchDescriptor<DrawbridgeEvent>()
        if let events = try? modelContext.fetch(descriptor) {
            modelContext.delete(events)
            try? modelContext.save()
            SecurityLogger.main("🧹 Cleared \(events.count) events from SwiftData")
        }
    }
    ```

- [ ] **Optimize DebugView clear function**
  - File: `Packages/BridgetSettings/Sources/BridgetSettings/DebugView.swift`
  - Current: Loop-based deletion
  - Target: Batch deletion
  - Code:
    ```swift
    private func clearEvents() {
        let descriptor = FetchDescriptor<DrawbridgeEvent>()
        if let oldEvents = try? modelContext.fetch(descriptor) {
            modelContext.delete(oldEvents)
            try? modelContext.save()
            SecurityLogger.main("🧹 Cleared \(oldEvents.count) old events from SwiftData (DebugView)")
        }
    }
    ```

#### 5. Add Data Validation

- [ ] **Add validation to DrawbridgeEvent**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeEvent.swift`
  - Action: Add validation in initializer
  - Code:
    ```swift
    public init(entityType: String, entityName: String, entityID: Int, ...) {
        guard entityID > 0 else {
            fatalError("Entity ID must be positive")
        }
        guard !entityName.isEmpty else {
            fatalError("Entity name cannot be empty")
        }
        guard !entityType.isEmpty else {
            fatalError("Entity type cannot be empty")
        }
        guard minutesOpen >= 0 else {
            fatalError("Minutes open cannot be negative")
        }
        // ... rest of initialization
    }
    ```

- [ ] **Add validation to DrawbridgeInfo**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeInfo.swift`
  - Action: Add validation in initializer
  - Code:
    ```swift
    public init(entityID: Int, entityName: String, entityType: String, ...) {
        guard entityID > 0 else {
            fatalError("Entity ID must be positive")
        }
        guard !entityName.isEmpty else {
            fatalError("Entity name cannot be empty")
        }
        guard !entityType.isEmpty else {
            fatalError("Entity type cannot be empty")
        }
        // ... rest of initialization
    }
    ```

#### 6. Implement Fetch Descriptors

- [ ] **Add utility functions for complex queries**
  - File: `Packages/BridgetCore/Sources/BridgetCore/Utilities.swift`
  - Action: Add SwiftData query utilities
  - Code:
    ```swift
    // MARK: - SwiftData Query Utilities
    
    public struct SwiftDataQueries {
        public static func fetchEventsForBridge(
            _ bridgeID: Int, 
            in dateRange: DateInterval,
            context: ModelContext
        ) -> [DrawbridgeEvent] {
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: #Predicate<DrawbridgeEvent> { event in
                    event.entityID == bridgeID &&
                    event.openDateTime >= dateRange.start &&
                    event.openDateTime <= dateRange.end
                },
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            return (try? context.fetch(descriptor)) ?? []
        }
        
        public static func fetchRecentEvents(
            days: Int,
            context: ModelContext
        ) -> [DrawbridgeEvent] {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: #Predicate<DrawbridgeEvent> { event in
                    event.openDateTime >= cutoffDate
                },
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            return (try? context.fetch(descriptor)) ?? []
        }
    }
    ```

### Low Priority Tasks

#### 7. Add Soft Deletes

- [ ] **Add soft delete support to DrawbridgeEvent**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeEvent.swift`
  - Action: Add soft delete properties and methods
  - Code:
    ```swift
    @Model
    @Bindable
    public final class DrawbridgeEvent {
        // ... existing properties
        public var isDeleted: Bool = false
        public var deletedAt: Date?
        
        public func softDelete() {
            isDeleted = true
            deletedAt = Date()
        }
        
        public func restore() {
            isDeleted = false
            deletedAt = nil
        }
    }
    ```

#### 8. Consider Model Relationships

- [ ] **Add relationships between models**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeEvent.swift`
  - Action: Add relationship to analytics
  - Code:
    ```swift
    @Model
    @Bindable
    public final class DrawbridgeEvent {
        // ... existing properties
        @Relationship(deleteRule: .cascade) public var analytics: [BridgeAnalytics]?
    }
    ```

- [ ] **Add relationships to DrawbridgeInfo**
  - File: `Packages/BridgetCore/Sources/BridgetCore/DrawbridgeInfo.swift`
  - Action: Add relationship to events
  - Code:
    ```swift
    @Model
    @Bindable
    public final class DrawbridgeInfo {
        // ... existing properties
        @Relationship(deleteRule: .cascade) public var events: [DrawbridgeEvent]?
    }
    ```

### Testing Tasks

#### 9. Update Tests for New Features

- [ ] **Update test files for @Bindable**
  - Files: All test files using SwiftData
  - Action: Ensure tests work with automatic saves
  - Impact: Maintain test coverage

- [ ] **Add tests for new query predicates**
  - File: `BridgetTests/ComprehensiveUITests.swift`
  - Action: Test filtered queries
  - Code:
    ```swift
    func testFilteredQueries() {
        // Test that filtered queries return expected results
    }
    ```

- [ ] **Add tests for batch operations**
  - File: `BridgetTests/ComprehensiveUITests.swift`
  - Action: Test batch delete operations
  - Code:
    ```swift
    func testBatchOperations() {
        // Test batch delete performance
    }
    ```

### Documentation Tasks

#### 10. Update Documentation

- [ ] **Update API documentation**
  - File: `Documentation/API_DOCUMENTATION_GENERATOR.md`
  - Action: Document new SwiftData patterns
  - Impact: Help developers use new features

- [ ] **Create SwiftData best practices guide**
  - File: `Documentation/SWIFTDATA_BEST_PRACTICES.md`
  - Action: Document recommended patterns
  - Impact: Establish coding standards

### Performance Monitoring

#### 11. Add Performance Metrics

- [ ] **Add query performance logging**
  - Files: All files with @Query
  - Action: Log query execution times
  - Code:
    ```swift
    let startTime = Date()
    // ... query execution
    let duration = Date().timeIntervalSince(startTime)
    SecurityLogger.performance("Query executed in \(duration)s")
    ```

- [ ] **Add memory usage monitoring**
  - Files: All files with large data sets
  - Action: Monitor memory usage
  - Code:
    ```swift
    SecurityLogger.performance("Memory usage: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
    ```

## Implementation Order

### Phase 1 (Week 1): Foundation
1. Clean up unused models
2. Add @Bindable to core models
3. Add data validation

### Phase 2 (Week 2): Performance
1. Add @Query predicates
2. Implement batch operations
3. Add fetch descriptors

### Phase 3 (Week 3): Advanced Features
1. Add soft deletes
2. Add model relationships
3. Update tests

### Phase 4 (Week 4): Monitoring & Documentation
1. Add performance metrics
2. Update documentation
3. Final testing and validation

## Success Criteria

- [ ] All @Query properties use predicates for filtering
- [ ] All models use @Bindable for automatic saves
- [ ] All bulk operations use batch methods
- [ ] All models have proper validation
- [ ] Test coverage remains at 90%+
- [ ] Performance improves by 20%+
- [ ] Memory usage decreases by 15%+

## Risk Mitigation

- **Breaking Changes**: Test thoroughly before merging
- **Performance Regression**: Monitor metrics during implementation
- **Data Loss**: Backup before making schema changes
- **Test Failures**: Update tests incrementally with each change 