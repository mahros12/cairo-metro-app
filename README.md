# 🚇 Cairo Metro App (مترو القاهرة)

A modern, intelligent, and feature-rich Flutter application designed for navigating the Greater Cairo Metro network. The app offers real-time route planning, direction guidance, landmark-based nearest station discovery with Arabic & English NLP, fare calculations, and an optimized dark mode.

---

## ✨ Features

### 🧭 1. Intelligent Route Planning & Direction Guidance
- **Dual Routing Optimization**:
  - **Shortest Path**: Minimizes the total number of stations and estimated travel time.
  - **Least Transitions**: Prioritizes routes with fewer line transfers for a smoother trip.
- **Direction & Boarding Detection**:
  - Automatically identifies the boarding train direction (e.g., *"Helwan direction"* or *"Adly Mansour direction"*).
  - Clear step-by-step transfer instructions when switching lines (e.g., *"Transfer from Line 1 to Line 3 towards Cairo University"*).
- **Interactive Timeline**:
  - Visual route progression showing origin, transfer nodes, intermediate stops, and destination with line-colored badges.

### 📍 2. Location-Based & Landmark Place Search
- **GPS Current Location**:
  - One-tap button to detect the user's real-time GPS position and automatically assign the nearest metro station as origin.
- **Landmark & Destination Search (NLP)**:
  - Search any destination or landmark (e.g., *"Merryland"*, *"الميرلاند"*, *"Cairo Tower"*, *"Al-Azhar University"*).
  - Built-in **Natural Language Processing (NLP)** service supporting Arabic and English normalization, transliteration, and fuzzy matching to eliminate garbage results.
  - **Hybrid Search**: Combines live geocoding with a curated offline landmark database for instant offline access.

### 🎫 3. Dynamic Ticketing & Fare Calculation
- **Official Cairo Metro Fare Tiers**:
  - Tier 1: 1–9 Stations (10 EGP)
  - Tier 2: 10–16 Stations (12 EGP)
  - Tier 3: 17–23 Stations (15 EGP)
  - Tier 4: More than 23 Stations (20 EGP)
- **Passenger Categories & Concessions**:
  - **Standard Passenger**: Standard fare based on station count.
  - **Senior (Over 60)**: 50% discount on all tiers.
  - **Special Needs / Disability**: Fixed nominal fare (5 EGP) across all zones.

### 🎨 4. Line Branding & Optimized Dark Mode
- **Metro Line Branding**:
  - 🔵 **Line 1 (Blue)**: Helwan ↔ El Marg El Gedida
  - 🔴 **Line 2 (Red)**: Shubra El Kheima ↔ El Mounib
  - 🟢 **Line 3 (Green)**: Adly Mansour ↔ Kit Kat / Cairo University / Rod El Farag
- **Full Dark Mode & Light Mode**:
  - Deep slate OLED-friendly dark theme hierarchy (`#0F172A` background, `#1E293B` cards, `#253346` containers).
  - No harsh or low-contrast containers; all cards, banners, timeline nodes, and inputs adapt seamlessly.
  - Instant toggle button in the navigation bar.

### 💾 5. Local Storage & Persistence
- Automatically persists user login profile and preferences locally using `SharedPreferences`.
- Direct auto-routing to the Home screen on subsequent launches without prompting login again.
- Remembers dark/light mode preference across app restarts.

---

## 🏗️ Project Architecture

The project follows a clean, reactive architectural pattern with separation of concerns:

```
lib/
├── controllers/            # GetX State Management Controllers
│   ├── route_controller.dart     # Routing states, selected paths, transitions
│   ├── theme_controller.dart     # Dark/Light theme state & SharedPreferences
│   └── user_controller.dart      # User auth state, categories, ticket discounts
├── data/
│   └── metro_network.dart        # Stations graph, coordinates, lines, and interchanges
├── models/
│   ├── route_step.dart           # Step breakdown (board, transfer, ride, arrive)
│   ├── station.dart              # Station model with coordinates and lines
│   └── traversal_state.dart      # Graph search state for pathfinding
├── screens/
│   ├── home_screen.dart          # Main dashboard (origin/destination, search, cards)
│   ├── login_screen.dart         # User onboarding & passenger category selection
│   ├── route_screen.dart         # Route overview & timeline visualization
│   ├── route_details_screen.dart # Detailed directions & navigation steps
│   └── welcome_temp_screen.dart  # Temporary transition screen
├── services/
│   ├── coordinate_service.dart   # Great-circle distance (Haversine) calculations
│   ├── maps_service.dart         # Google Maps / external maps launcher
│   ├── nlp_search_service.dart   # Arabic/English search NLP & query processing
│   ├── place_search_service.dart # Landmark lookup, geocoding & offline cache
│   └── routing_service.dart      # Dijkstra & BFS pathfinding algorithms
├── utils/
│   └── metro_theme.dart          # Line colors, adaptive palettes, typography, theme data
└── widgets/
    ├── route_timeline_tile.dart  # Station node & transfer step tile
    ├── route_timeline_view.dart  # Full journey timeline
    ├── station_selector_header.dart # Origin/Destination selector & station bottom sheet
    ├── ticket_pricing_card.dart  # Pricing breakdown & route option tabs
    └── trip_summary_card.dart    # Trip metrics, estimated time & direction banner
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.0.0`)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator with Location permissions enabled

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/cairo_metro_app.git
   cd cairo_metro_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run static analysis**:
   ```bash
   flutter analyze
   ```

4. **Run the automated test suite**:
   ```bash
   flutter test
   ```

5. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The codebase includes comprehensive unit and widget tests covering:
- Graph construction and station integrity across all 3 lines.
- Multi-line transfer detection (e.g., Sadat, Attaba, Nasser, Cairo University).
- Train direction resolution (origin towards destination terminus).
- Dynamic pricing and concession rules (Standard, Senior 50%, Special Needs 5 EGP).
- Arabic & English NLP landmark lookup.
- Theme switching and local persistence.

Run tests using:
```bash
flutter test
```

---

## 📦 Dependencies

| Package | Version | Purpose |
| :--- | :--- | :--- |
| [`get`](https://pub.dev/packages/get) | `^4.7.3` | Reactive state management, routing, and snackbars |
| [`geolocator`](https://pub.dev/packages/geolocator) | `^14.1.1` | Real-time GPS location access |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `^2.5.6` | Local storage persistence for user profile & theme |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | `^6.3.0` | External navigation & Google Maps integration |
| [`collection`](https://pub.dev/packages/collection) | `^1.19.1` | Advanced collection and iterable utilities |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | `^1.0.8` | iOS-style iconography |

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
