# 🏗️ Bridget – Seattle Bridge Traffic & Smart Routing App

**Bridget** is an intelligent iOS app for monitoring Seattle drawbridge openings, predicting traffic patterns, and planning smarter routes. Powered by AI and a modular Swift architecture, Bridget helps commuters, cyclists, and travelers avoid bridge delays and get to their destinations on time.

---

## 🚀 Features

- **Bridge Status**: Historical and recent bridge opening data for Seattle drawbridges, updated as data becomes available from public sources.
- **AI-Powered Predictions**: Probability scoring, duration estimates, and smart reasoning for bridge openings.
- **Traffic Cascade Detection**: See how one bridge opening affects others.
- **Route Planning**: Apple Maps integration, bridge-aware routing, and alternative route suggestions.
- **Motion-Aware Predictions**: Uses device motion sensors to improve prediction accuracy.
- **Advanced Statistics Dashboard**: Historical pattern analysis, network diagrams, and traffic impact summaries.
- **Modern SwiftUI Interface**: iOS 17+ design, dark mode, accessibility, and smooth animations.
- **Smart Notifications**: Proactive alerts for bridge openings and traffic changes.
- **Privacy-First**: No personal data collection; all processing is local and secure.

---

## 🧩 Modular Architecture

Bridget is built with 10 Swift Package Manager modules for maintainability and performance:

```
Bridget/
├── BridgetCore/          # SwiftData models and services
├── BridgetDashboard/     # Main dashboard interface
├── BridgetBridgeDetail/  # Bridge details and analysis
├── BridgetBridgesList/   # Bridge listing and management
├── BridgetRouting/       # Route planning and optimization
├── BridgetStatistics/    # Analytics and statistics
├── BridgetHistory/       # Historical data tracking
├── BridgetNetworking/    # API and data fetching
├── BridgetSettings/      # User preferences and config
└── BridgetSharedUI/      # Reusable UI components
```

---

## 📱 Getting Started

### Requirements

- iOS 17.0 or later
- Xcode 15+
- iPhone, iPad, or iPod touch

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/PeterJemley/Bridget.git
   ```
2. **Open in Xcode:**
   - Open `Bridget.xcodeproj`.
   - Ensure all Swift packages resolve correctly.
3. **Build & Run:**
   - Use the iPhone 16 Pro simulator (recommended) or your real device.
   - Grant location and motion permissions when prompted.

---

## 🏆 What Makes Bridget Special?

- **Predicts bridge openings before they happen** using AI and months of historical data.
- **Understands traffic chain reactions**—when one bridge opens, others often follow.
- **Adapts to your travel context** (vehicle, cycling, etc.) for more relevant predictions.
- **Continuously learns** from new data and device capabilities.

---

## 🛠️ Development & Testing

- **95% test coverage**: Comprehensive unit, UI, and integration tests.
- **Manual and automated testing**: See `MANUAL_TESTING_CHECKLIST.md` and `TESTING_INTEGRATION_GUIDE.md`.
- **Stable build system**: All critical build issues resolved.

---

## 🚧 Roadmap & Unimplemented Features

- **ARIMA Prediction Engine**: Advanced forecasting (in progress)
- **Background Processing**: Location and motion detection in background
- **Advanced Analytics**: Deeper statistical insights and ML models
- **Social & Community Features**: Route sharing, ratings, and collaboration

See `UNIMPLEMENTED_FEATURES.md` for details.

---

## 📄 Documentation

- [Feature Overview](FEATURES.md)
- [Modularization Guide](MODULARIZATION_GUIDE.md)
- [Statistics User Guide](STATISTICS_USER_GUIDE.md)
- [Motion Detection Implementation](MOTION_DETECTION_IMPLEMENTATION_GUIDE.md)
- [Refactoring Summary](REFACTORING_SUMMARY.md)
- [Manual Testing Checklist](MANUAL_TESTING_CHECKLIST.md)
- [Background Agents](BACKGROUND_AGENTS.md)

---

## 🛡️ Privacy & Security

- No personal data collection—only public bridge data is used.
- All motion and location processing is local to your device.
- Secure API communication and privacy-first design.

---

## 📬 Support & Contributions

- **Issues & Feature Requests**: Please use the GitHub Issues tab.
- **Pull Requests**: Contributions are welcome! See our modular architecture for guidance.

---

## 📢 Catch Phrase

> Ditch the spanxiety: Bridge the gap between *you* and *on time*

--- 