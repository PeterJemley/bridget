import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct DashboardView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    public let motionService: MotionDetectionService?
    public let backgroundAgent: BackgroundTrafficAgent?
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo], motionService: MotionDetectionService? = nil, backgroundAgent: BackgroundTrafficAgent? = nil) {
        self.events = events
        self.bridgeInfo = bridgeInfo
        self.motionService = motionService
        self.backgroundAgent = backgroundAgent
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                    
                    if !events.isEmpty {
                        Button(action: {
                            openSeattleDataAPI()
                        }) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Seattle Open Data API")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    StatusOverviewCard(events: events, bridgeInfo: bridgeInfo)
                    
                    LastKnownStatusSection(events: lastKnownStatusEvents, bridgeInfo: bridgeInfo)
                    
                    RecentActivityToggleView(events: recentEvents, bridgeInfo: bridgeInfo)
                }
                .padding(16)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
    }
    
    private func openSeattleDataAPI() {
        if let url = URL(string: "https://data.seattle.gov/Transportation/SDOT-Drawbridge-Status/gm8h-9449/about_data") {
            UIApplication.shared.open(url)
        }
    }
    
    private var lastKnownStatusEvents: [DrawbridgeEvent] {
        let uniqueBridges = Set(events.map { $0.entityID })
        return uniqueBridges.compactMap { entityID in
            events.filter { $0.entityID == entityID }
                  .sorted { $0.openDateTime > $1.openDateTime }
                  .first
        }
        .sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var recentEvents: [DrawbridgeEvent] {
        let sortedEvents = events.sorted { $0.openDateTime > $1.openDateTime }
        return Array(sortedEvents.prefix(10))
    }
}

#Preview {
    DashboardView(events: [], bridgeInfo: [], motionService: nil, backgroundAgent: nil)
}