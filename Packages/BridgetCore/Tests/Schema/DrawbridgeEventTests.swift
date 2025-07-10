import Testing
import SwiftData
import BridgetCore

@Suite("DrawbridgeEvent SwiftData Tests")
struct DrawbridgeEventTests {
    @Test
    func createReadUpdateDelete() async throws {
        let context = try makeInMemoryModelContext()
        // Create
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Fremont",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 12.5,
            latitude: 47.65,
            longitude: -122.34
        )
        context.insert(event)
        try context.save()
        // Read
        let results = try context.fetch(DrawbridgeEvent.self)
        #expect(results.count == 1)
        #expect(results.first?.entityName == "Fremont")
        // Update
        event.minutesOpen = 15.0
        try context.save()
        #expect(try context.fetch(DrawbridgeEvent.self).first?.minutesOpen == 15.0)
        // Delete
        context.delete(event)
        try context.save()
        #expect((try context.fetch(DrawbridgeEvent.self)).isEmpty)
    }

    @Test
    func edgeCases() async throws {
        let context = try makeInMemoryModelContext()
        let event = DrawbridgeEvent(
            entityType: "",
            entityName: "",
            entityID: 2,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0,
            latitude: 0,
            longitude: 0
        )
        context.insert(event)
        try context.save()
        let fetched = try context.fetch(DrawbridgeEvent.self).first
        #expect(fetched?.entityType == "")
        #expect(fetched?.entityName == "")
    }

    @Test
    func uniqueEntityID() async throws {
        let context = try makeInMemoryModelContext()
        let event1 = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Ballard",
            entityID: 3,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 10,
            latitude: 47.67,
            longitude: -122.38
        )
        let event2 = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Ballard",
            entityID: 3,
            openDateTime: Date().addingTimeInterval(60),
            closeDateTime: nil,
            minutesOpen: 8,
            latitude: 47.67,
            longitude: -122.38
        )
        context.insert(event1)
        context.insert(event2)
        try context.save()
        let all = try context.fetch(DrawbridgeEvent.self)
        #expect(all.count == 2)
    }

    @Test
    func performanceOfBulkInsertAndFetch() async throws {
        let context = try makeInMemoryModelContext()
        for i in 0..<5000 {
            let event = DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "StressTest",
                entityID: i,
                openDateTime: Date(),
                closeDateTime: nil,
                minutesOpen: Double(i % 60),
                latitude: 47.0 + Double(i % 10),
                longitude: -122.0 - Double(i % 10)
            )
            context.insert(event)
        }
        try context.save()
        let fetched = try context.fetch(DrawbridgeEvent.self)
        #expect(fetched.count == 5000)
    }
} 