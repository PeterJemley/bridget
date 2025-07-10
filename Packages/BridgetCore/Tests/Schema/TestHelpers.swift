import SwiftData
import BridgetCore

func makeInMemoryModelContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: [DrawbridgeEvent.self, DrawbridgeInfo.self, BridgeAnalytics.self, CascadeEvent.self],
        configurations: [.default: .inMemory]
    )
    return container.mainContext
} 