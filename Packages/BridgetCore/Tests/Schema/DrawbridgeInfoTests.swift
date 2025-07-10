import Testing
import SwiftData
import BridgetCore

@Suite("DrawbridgeInfo SwiftData Tests")
struct DrawbridgeInfoTests {
    @Test
    func createReadUpdateDelete() async throws {
        let context = try makeInMemoryModelContext()
        let info = DrawbridgeInfo(
            entityID: 100,
            entityName: "Montlake",
            entityType: "Bridge",
            latitude: 47.64,
            longitude: -122.30
        )
        context.insert(info)
        try context.save()
        let results = try context.fetch(DrawbridgeInfo.self)
        #expect(results.count == 1)
        #expect(results.first?.entityName == "Montlake")
        info.latitude = 47.65
        try context.save()
        #expect(try context.fetch(DrawbridgeInfo.self).first?.latitude == 47.65)
        context.delete(info)
        try context.save()
        #expect((try context.fetch(DrawbridgeInfo.self)).isEmpty)
    }

    @Test
    func uniqueEntityIDConstraint() async throws {
        let context = try makeInMemoryModelContext()
        let info1 = DrawbridgeInfo(
            entityID: 200,
            entityName: "University",
            entityType: "Bridge",
            latitude: 47.66,
            longitude: -122.31
        )
        let info2 = DrawbridgeInfo(
            entityID: 200,
            entityName: "University",
            entityType: "Bridge",
            latitude: 47.66,
            longitude: -122.31
        )
        context.insert(info1)
        try context.save()
        context.insert(info2)
        do {
            try context.save()
            #expect(false, "Expected unique constraint violation")
        } catch {
            #expect(true)
        }
    }

    @Test
    func edgeCases() async throws {
        let context = try makeInMemoryModelContext()
        let info = DrawbridgeInfo(
            entityID: 201,
            entityName: "",
            entityType: "",
            latitude: 0,
            longitude: 0
        )
        context.insert(info)
        try context.save()
        let fetched = try context.fetch(DrawbridgeInfo.self).first
        #expect(fetched?.entityName == "")
        #expect(fetched?.entityType == "")
    }

    @Test
    func performanceOfBulkInsertAndFetch() async throws {
        let context = try makeInMemoryModelContext()
        for i in 0..<1000 {
            let info = DrawbridgeInfo(
                entityID: i + 1000,
                entityName: "BulkTest",
                entityType: "Bridge",
                latitude: 47.0 + Double(i % 10),
                longitude: -122.0 - Double(i % 10)
            )
            context.insert(info)
        }
        try context.save()
        let fetched = try context.fetch(DrawbridgeInfo.self)
        #expect(fetched.count == 1000)
    }
} 