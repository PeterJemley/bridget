import Testing
import SwiftData
import BridgetCore

@Suite("CascadeEvent SwiftData Tests")
struct CascadeEventTests {
    @Test
    func createReadUpdateDelete() async throws {
        let context = try makeInMemoryModelContext()
        let event = CascadeEvent(
            triggerBridgeID: 1,
            triggerBridgeName: "Fremont",
            targetBridgeID: 2,
            targetBridgeName: "Ballard",
            triggerTime: Date(),
            targetTime: Date().addingTimeInterval(60),
            triggerDuration: 10,
            targetDuration: 8,
            cascadeStrength: 0.7,
            cascadeType: "temporal"
        )
        context.insert(event)
        try context.save()
        let results = try context.fetch(CascadeEvent.self)
        #expect(results.count == 1)
        #expect(results.first?.triggerBridgeName == "Fremont")
        event.cascadeStrength = 0.9
        try context.save()
        #expect(try context.fetch(CascadeEvent.self).first?.cascadeStrength == 0.9)
        context.delete(event)
        try context.save()
        #expect((try context.fetch(CascadeEvent.self)).isEmpty)
    }

    @Test
    func edgeCases() async throws {
        let context = try makeInMemoryModelContext()
        let event = CascadeEvent(
            triggerBridgeID: 0,
            triggerBridgeName: "",
            targetBridgeID: 0,
            targetBridgeName: "",
            triggerTime: Date(),
            targetTime: Date(),
            triggerDuration: 0,
            targetDuration: 0,
            cascadeStrength: 0,
            cascadeType: ""
        )
        context.insert(event)
        try context.save()
        let fetched = try context.fetch(CascadeEvent.self).first
        #expect(fetched?.triggerBridgeName == "")
        #expect(fetched?.targetBridgeName == "")
    }

    @Test
    func performanceOfBulkInsertAndFetch() async throws {
        let context = try makeInMemoryModelContext()
        for i in 0..<1000 {
            let event = CascadeEvent(
                triggerBridgeID: i,
                triggerBridgeName: "Trigger",
                targetBridgeID: i + 1,
                targetBridgeName: "Target",
                triggerTime: Date(),
                targetTime: Date().addingTimeInterval(Double(i)),
                triggerDuration: Double(i % 10),
                targetDuration: Double(i % 10),
                cascadeStrength: Double(i % 100) / 100.0,
                cascadeType: "test"
            )
            context.insert(event)
        }
        try context.save()
        let fetched = try context.fetch(CascadeEvent.self)
        #expect(fetched.count == 1000)
    }
} 