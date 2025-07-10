import Testing
import SwiftData
import BridgetCore

@Suite("BridgeAnalytics SwiftData Tests")
struct BridgeAnalyticsTests {
    @Test
    func createReadUpdateDelete() async throws {
        let context = try makeInMemoryModelContext()
        let analytics = BridgeAnalytics(
            entityID: 1,
            entityName: "Fremont",
            year: 2025,
            month: 6,
            dayOfWeek: 2,
            hour: 8
        )
        context.insert(analytics)
        try context.save()
        let results = try context.fetch(BridgeAnalytics.self)
        #expect(results.count == 1)
        #expect(results.first?.entityName == "Fremont")
        analytics.openingCount = 5
        try context.save()
        #expect(try context.fetch(BridgeAnalytics.self).first?.openingCount == 5)
        context.delete(analytics)
        try context.save()
        #expect((try context.fetch(BridgeAnalytics.self)).isEmpty)
    }

    @Test
    func edgeCases() async throws {
        let context = try makeInMemoryModelContext()
        let analytics = BridgeAnalytics(
            entityID: 2,
            entityName: "",
            year: 2025,
            month: 1,
            dayOfWeek: 1,
            hour: 0
        )
        context.insert(analytics)
        try context.save()
        let fetched = try context.fetch(BridgeAnalytics.self).first
        #expect(fetched?.entityName == "")
    }

    @Test
    func performanceOfBulkInsertAndFetch() async throws {
        let context = try makeInMemoryModelContext()
        for i in 0..<1000 {
            let analytics = BridgeAnalytics(
                entityID: i,
                entityName: "BulkAnalytics",
                year: 2025,
                month: 1,
                dayOfWeek: 1,
                hour: i % 24
            )
            context.insert(analytics)
        }
        try context.save()
        let fetched = try context.fetch(BridgeAnalytics.self)
        #expect(fetched.count == 1000)
    }
} 