# Accessibility Audit Report
Generated on: Sat Jul 12 06:13:54 PDT 2025

## Accessibility Properties Found

### BridgetSharedUITests.swift
**Path:** /Users/peterjemley/Documents/Developer/Bridget/Bridget/Packages/BridgetSharedUI/Tests/BridgetSharedUITests/BridgetSharedUITests.swift

- Line 161:        // Test that components support accessibility

### EnhancedInsightCard.swift
**Path:** /Users/peterjemley/Documents/Developer/Bridget/Bridget/Packages/BridgetSharedUI/Sources/BridgetSharedUI/EnhancedInsightCard.swift

- Line 89:        .accessibilityElement(children: .combine)
- Line 90:        .accessibilityLabel(Text("\(title): \(value), \(subtitle)"))
- Line 91:        .accessibilityHint(Text("Insight card showing \(title.lowercased()) with trend visualization"))

### HistoryView.swift
**Path:** /Users/peterjemley/Documents/Developer/Bridget/Bridget/Packages/BridgetHistory/Sources/BridgetHistory/HistoryView.swift

- Line 262:        .accessibilityElement(children: .contain)
- Line 263:        .accessibilityLabel(Text("Opening Frequency Over Time Chart"))
- Line 264:        .accessibilityHint(Text("Bar chart showing the number of bridge openings per period. The highest bar indicates the peak period."))
- Line 274:                    .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 279:                    .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 286:                    .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 291:                    .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 336:                                .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 341:                                .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 358:                            .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 380:        .accessibilityLabel(Text("\(item.data.displayLabel)"))
- Line 381:        .accessibilityValue(Text("\(item.data.count) events"))
- Line 392:        .accessibilityLabel(Text("Other"))
- Line 393:        .accessibilityValue(Text("\(chartData.aggregatedCount) events aggregated"))
- Line 416:                    .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 424:                        .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 429:                        .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 436:                        .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 441:                        .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 448:                        .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 457:                            .dynamicTypeSize(.xSmall ... .accessibility3)
- Line 459:                    .accessibilityElement(children: .combine)
- Line 460:                    .accessibilityLabel(Text("Trend"))
- Line 461:                    .accessibilityValue(Text(frequencyTrend))

### MapActivityViewTests.swift
**Path:** /Users/peterjemley/Documents/Developer/Bridget/Bridget/Packages/BridgetDashboard/Tests/BridgetDashboardTests/MapActivityViewTests.swift

- Line 244:        // In a real app, you would test accessibility labels and hints here

### ComprehensiveUITests.swift
**Path:** /Users/peterjemley/Documents/Developer/Bridget/Bridget/BridgetUITests/ComprehensiveUITests.swift

- Line 428:        // Then: Elements should have accessibility labels
- Line 434:            XCTAssertFalse(element.label.isEmpty, "Bridge element should have accessibility label")

