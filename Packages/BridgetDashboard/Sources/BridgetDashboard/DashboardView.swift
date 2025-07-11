import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct DashboardView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    public let motionService: MotionDetectionService?
    public let backgroundAgent: BackgroundTrafficAgent?
    public let onNavigateToRoutes: (() -> Void)?
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo], motionService: MotionDetectionService? = nil, backgroundAgent: BackgroundTrafficAgent? = nil, onNavigateToRoutes: (() -> Void)? = nil) {
        self.events = events
        self.bridgeInfo = bridgeInfo
        self.motionService = motionService
        self.backgroundAgent = backgroundAgent
        self.onNavigateToRoutes = onNavigateToRoutes
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusOverviewSection
                    recentActivitySection
                    motionStatusSection
                    backgroundMonitoringSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                SecurityLogger.main("🏠 [DASHBOARD] DashboardView appeared")
                SecurityLogger.main("🏠 [DASHBOARD] Total events: \(events.count)")
                SecurityLogger.main("🏠 [DASHBOARD] Total bridge info: \(bridgeInfo.count)")
                SecurityLogger.main("🏠 [DASHBOARD] Motion service available: \(motionService != nil)")
                SecurityLogger.main("🏠 [DASHBOARD] Background agent available: \(backgroundAgent != nil)")
                let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
                SecurityLogger.main("🏠 [DASHBOARD] BRIDGE BREAKDOWN:")
                for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
                    SecurityLogger.main("    • \(bridgeName): \(bridgeEvents.count) events")
                }
            }
        }
    }
    
    // MARK: - Private Section Views
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "laurel.leading")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Bridget")
                    .font(.title2)
                    .fontWeight(.bold)
                Image(systemName: "laurel.trailing")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            let catchPhrase: Text =
                Text("Ditch the spanxiety: Bridge the gap between ") +
                Text("you").italic() +
                Text(" and ") +
                Text("on time").italic()
            catchPhrase
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    private var statusOverviewSection: some View {
        StatusOverviewCard(events: events, bridgeInfo: bridgeInfo, onNavigateToRoutes: onNavigateToRoutes)
    }
    
    private var lastKnownStatusSection: some View {
        LastKnownStatusSection(events: events, bridgeInfo: bridgeInfo)
    }
    
    private var recentActivitySection: some View {
        RecentActivityToggleView(events: events, bridgeInfo: bridgeInfo)
    }
    
    private var motionStatusSection: some View {
        Group {
            if let motionService = motionService {
                MotionStatusCard(motionService: motionService)
            }
        }
    }
    
    private var backgroundMonitoringSection: some View {
        Group {
            if let backgroundAgent = backgroundAgent {
                BackgroundMonitoringCard(backgroundAgent: backgroundAgent)
            }
        }
    }
}

#Preview {
    DashboardView(events: [], bridgeInfo: [], motionService: nil, backgroundAgent: nil)
}