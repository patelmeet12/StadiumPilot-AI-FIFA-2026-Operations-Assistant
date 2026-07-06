# StadiumPilot AI - FIFA World Cup 2026™ Assistant

An intelligent, context-aware operational assistant designed to optimize stadium logistics, fan experiences, volunteer checklists, and organizer decisions during the FIFA World Cup 2026.

---

## 📋 Problem Statement

Managing stadium operations for a mega-event like the FIFA World Cup presents immense challenges:
* **Crowd Congestion & Safety**: Major bottlenecks at entrances and concessions increase queue wait times and raise security/crush hazards.
* **Complex Multi-Modal Commutes**: Directing thousands of fans to eco-friendly transit methods while preventing local gridlock.
* **Diverse User Accessibility Needs**: Insufficient localized routing for fans with wheelchairs, sensory sensitivities, visual impairments, or senior requirements.
* **Fragmented Operational Roles**: Volunteers and venue staff lack a unified dashboard to coordinate incident resolutions, checklist completions, and real-time crowd dispatching.

---

## 🚀 Solution Overview

**StadiumPilot AI** acts as a unified tournament operations center. It provides dedicated portals for Fans, Volunteers, Organizers, and Venue Staff. Powered by a client-side AI Decision Support Engine, the application continuously streams crowd levels, transit queues, and safety alerts to formulate real-time personalized recommendations.

---

## 🏛 Architecture

StadiumPilot AI follows **Clean Architecture** and strict **SOLID Principles**:

```
lib/
├── core/
│   ├── localization/      # Custom offline translation dictionary (EN, ES, FR, HI, AR, PT)
│   ├── routing/           # GoRouter deep-linking definitions
│   └── theme/             # Brand-aligned Dark, Light, and High-Contrast Themes
├── domain/
│   ├── entities/          # Core data structures (UserRole, CrowdState, RoutePlan, etc.)
│   ├── repositories/      # Interface contracts for stadium data providers
│   └── usecases/          # Business logic engines (Route finding, transit lookup, AI alerts)
├── data/
│   ├── datasources/       # Static datasets representing FIFA venue mock setups
│   └── repositories/      # Repository implementations saving simulator variables to SharedPreferences
└── presentation/
    ├── providers/         # State management using Riverpod (Crowd loop, theme, incidents state)
    ├── widgets/           # Shared components (Responsive layout shell, navigation widgets)
    └── pages/             # Dedicated feature dashboards (Fan desk, Volunteer checklist, Organizer map)
```

---

## 🧠 AI Decision Engine & Crowd Intelligence Logic

The **AI Decision Support Engine** (`GetAIRecommendations`) acts as the brains of the platform. It operates reactively on the state of the stadium:
1. **Dynamic Congestion Triggers**: When crowd sensors detect a wait time at Gate B exceeding 20 minutes, the engine generates bypass recommendation alerts redirecting fans to Gate D, resulting in an estimated benefit of ~20 minutes saved.
2. **Role-Based Suggestions**:
   * *Fans*: Receive mobile food queue warnings and recommendations to leave 10 minutes early or take Metro Line 2 to beat post-match transit queues.
   * *Volunteers*: Receive priority incident alerts directing them to locations requiring crowd marshalling or medical support.
   * *Organizers*: Receive critical safety alerts (e.g. gate operating at 145% capacity) requesting them to trigger stadium-wide redirect screens or dispatch personnel.

---

## ♿ Accessibility First

StadiumPilot AI implements deep accessibility integrations:
* **High Contrast Mode**: A dedicated, WCAG-compliant high contrast dark theme (pure black backgrounds, bold yellow buttons, larger typography) for visually impaired users.
* **Wheelchair-Friendly Routing**: Navigation paths that completely bypass stairways, utilize elevators, select wide automated scanners, and display step-free directions.
* **Sensory Spaces**: Mapped sensory safe rooms equipped with soundproofing to support neurodivergent fans.
* **Semantic Web Support**: All layouts are responsive, support standard tab-index keyboard navigation, and provide screen reader assist labels.

---

## 🧪 Testing Strategy

The repository includes a comprehensive unit testing suite under `test/`:
* **Navigation Tests**: Validates that wheelchair paths select elevators, and crowd bypass routing successfully routes away from congested gates.
* **Transit Tests**: Validates carbon footprint calculations and eco ratings.
* **Decision Engine Tests**: Ensures that recommendations correctly filter and raise priority based on user roles and incoming congestion sensors.

---

## ⚙️ Setup & Local Run Instructions

### Prerequisites
* Flutter SDK (3.38.x / Dart 3.10.x or higher)
* Chrome / Web Browser (for local running)

### Running the App
1. Clone this project or navigate to the directory:
   ```bash
   cd stadium_pilot_ai
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application locally in Chrome:
   ```bash
   flutter run -d chrome
   ```

### Running the Tests
Execute the unit tests verifying all decision logic:
   ```bash
   flutter test
   ```
