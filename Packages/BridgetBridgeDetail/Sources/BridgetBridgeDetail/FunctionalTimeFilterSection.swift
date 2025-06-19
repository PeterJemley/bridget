//
//  FunctionalTimeFilterSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct FunctionalTimeFilterSection: View {
    @Binding public var selectedPeriod: TimePeriod
    public let bridgeEvents: [DrawbridgeEvent]
    
    public init(selectedPeriod: Binding<TimePeriod>, bridgeEvents: [DrawbridgeEvent]) {
        self._selectedPeriod = selectedPeriod
        self.bridgeEvents = bridgeEvents
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Period")
                    .font(.headline)
                Spacer()
                Text("Showing \(eventsInPeriod) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    FilterButton(
                        title: periodTitle(for: period),
                        isSelected: selectedPeriod == period,
                        action: { selectedPeriod = period }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var eventsInPeriod: Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return bridgeEvents.filter { $0.openDateTime >= cutoffDate }.count
    }
    
    private func periodTitle(for period: TimePeriod) -> String {
        switch period {
        case .twentyFourHours: return "24H"
        case .sevenDays: return "7D"
        case .thirtyDays: return "30D"
        case .ninetyDays: return "90D"
        }
    }
}

#Preview {
    FunctionalTimeFilterSection(
        selectedPeriod: .constant(.sevenDays),
        bridgeEvents: []
    )
    .padding()
}