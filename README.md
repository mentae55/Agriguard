<div align="center">

<img src="assets/app_images/icons/logo.svg" width="120" height="120" alt="AgriGuard Logo"/>

# 🌿 AgriGuard

### *Smart Farming. Real-Time Intelligence. Zero Guesswork.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-66785F?style=for-the-badge)](LICENSE)

---

> **AgriGuard** is an intelligent agricultural monitoring system that connects farmers to their land through a smart robot, AI-powered plant diagnosis, real-time soil analytics, and live GPS tracking — all from the palm of their hand.

---

</div>

## 📖 Table of Contents

- [✨ Overview](#-overview)
- [🚀 Features](#-features)
- [📱 Screenshots](#-screenshots)
- [🏗️ Architecture](#️-architecture)
- [🛠️ Tech Stack](#️-tech-stack)
- [⚙️ Getting Started](#️-getting-started)
- [🔗 Device Connection Flow](#-device-connection-flow)
- [🤖 AI & Machine Learning](#-ai--machine-learning)
- [📡 Firebase Structure](#-firebase-structure)
- [🗺️ Roadmap](#️-roadmap)
- [🤝 Contributing](#-contributing)

---

## ✨ Overview

AgriGuard bridges the gap between traditional farming and cutting-edge technology. A physical **ESP32-powered robot** roams your fields, capturing soil data, plant images, and GPS coordinates — while the mobile app gives you complete visibility and control in real time.

Whether you're detecting nitrogen deficiency before it costs you a harvest, or remotely steering your robot to a specific crop row, AgriGuard puts precision agriculture within reach for every farmer.

---

## 🚀 Features

### 🌱 Plant Disease Diagnosis
- **AI-powered image classification** using a custom deep learning model hosted on Railway
- Supports **Tomato** and **Wheat** crops out of the box
- Detects conditions like *Late Blight*, *Early Blight*, *Yellow Leaf Curl*, *Rust*, and more
- Confidence scoring on every diagnosis
- Full chat session with **AgriGuard AI (Gemini-powered)** to ask follow-up questions

### 🤖 Robot Controller
- Real-time **directional control** (Forward / Backward / Left / Right / Stop) via Firebase
- **RUN mode** for sustained autonomous forward movement
- Live **online/offline detection** with automatic safety stop on disconnect
- Smooth animated D-pad interface with haptic-style feedback

### 🗺️ Live GPS Tracking
- Robot's location streamed live from Firebase → displayed on **Google Maps**
- "Follow Robot" camera mode that animates to the robot's position
- Route planning with **OSRM** routing engine (long-press to set destination)
- Live distance, duration & speed calculation

### 🌍 Soil Analysis Dashboard
- Real-time monitoring of **pH, Nitrogen (N), Phosphorus (P)**
- Visual health score with custom pie chart
- Weekly bar chart report with day-by-day trend
- Color-coded status indicators (Neutral / Attention / LOW)

### ☁️ Weather Details
- UV Index with gradient scale
- Sunrise / Sunset with animated arc visualization
- Wind compass, Rainfall prediction, Humidity & Feels-like temperature

### 🔔 Smart Alerts & Notifications
- Critical and Warning alert categories
- Detailed recommendations per alert (fertilization steps, robot battery management)
- Filterable alert tabs: All / Critical / Warning
- "View on Map" integration per alert

### 💬 AgriGuard AI Chat
- Powered by **Google Gemini 2.5 Flash**
- Context-aware responses grounded in the classification result
- Offline fallback with a rich local expert knowledge base
- Star (favorite) messages, chat history across sessions, multi-session management
- Suggestion chips for quick questions: *Organic treatments? Chemical control? Prevention steps?*

### 📡 Device Connectivity
- BLE (Bluetooth Low Energy) device discovery & pairing
- WiFi credential provisioning to ESP32 over BLE with **chunked data transfer**
- Firebase-based online/offline device monitoring (dual MAC path support)
- One-tap reconnection for saved devices

### 🔐 Authentication
- Email & Password login / registration
- Google Sign-In
- Password reset with verification screen
- Persistent session management via Firebase Auth

---

## 📱 Screenshots

| Onboarding | Login | Dashboard |
|:---:|:---:|:---:|
| *Welcome to smart farming* | *Secure authentication* | *Your farm at a glance* |

| Soil Analysis | Robot Controller | AI Chat |
|:---:|:---:|:---:|
| *NPK monitoring* | *Directional D-pad* | *Gemini-powered advice* |

| Live Map | Plant Diagnosis | Alerts |
|:---:|:---:|:---:|
| *GPS tracking* | *Disease detection* | *Real-time notifications* |

---

## 🏗️ Architecture

AgriGuard follows a clean **feature-first architecture** with clear separation of concerns:

```
lib/
├── core/
│   ├── constants/          # Colors, sizes, routes
│   └── widgets/            # Shared UI components, connectivity monitor
│
├── features/
│   ├── authentication/     # Login, Register, Forgot Password
│   │   ├── model/
│   │   ├── services/       # Firebase Auth cubit + service
│   │   ├── view/
│   │   └── view_model/
│   │
│   ├── chatbot/            # AI plant advisor
│   │   ├── model/          # ChatMessage, ChatSession
│   │   ├── services/       # Gemini, Classification, Firebase chat
│   │   ├── view/           # Chat, History, Favorites, Phone Capture
│   │   └── view_model/
│   │
│   ├── connection_to_device/  # BLE pairing & WiFi provisioning
│   │   ├── services/       # BleService, DeviceProvider
│   │   ├── view/
│   │   ├── view_model/
│   │   └── widgets/
│   │
│   ├── device_settings/    # Robot control + device config
│   │   ├── services/       # RobotControlService
│   │   └── view/           # DeviceSettingsScreen, RobotControlScreen
│   │
│   ├── home/               # Dashboard, Soil Analysis, Weather
│   ├── map/                # Google Maps + Robot GPS stream
│   ├── alerts/             # Alerts list + detail
│   ├── profile/            # User profile + edit
│   ├── onboarding/         # Intro screens
│   └── splash/             # Animated splash screen
│
└── main.dart               # App entry, providers, Firebase init
```

**State Management:** Provider + ChangeNotifier (ViewModels) alongside BLoC/Cubit for authentication.

**Data Flow:**
```
ESP32 Robot ──BLE──▶ App (WiFi credentials)
ESP32 Robot ──WiFi──▶ Firebase RTDB ──Stream──▶ App (GPS, status, sensor data)
App ──Firebase──▶ ESP32 (robot commands via /Devices/{MAC}/cmd)
App ──HTTP──▶ Railway API (plant image classification)
App ──HTTP──▶ Gemini API (AI chat responses)
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider, BLoC/Cubit |
| **Backend / Database** | Firebase Realtime Database |
| **Authentication** | Firebase Auth (Email + Google) |
| **AI Chat** | Google Gemini 2.5 Flash |
| **Plant Classification** | Custom ML model on Railway (FastAPI) |
| **Maps & Navigation** | Google Maps Flutter + OSRM Routing |
| **BLE Communication** | flutter_blue_plus |
| **Robot GPS** | Firebase RTDB streams |
| **UI Scaling** | flutter_screenutil |
| **Animations** | Lottie, AnimationController |

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code
- A Firebase project with Realtime Database enabled
- Google Maps API key (Android + iOS)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/agriguard.git
cd agriguard

# Install dependencies
flutter pub get

# Run on device
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password + Google)
3. Enable **Realtime Database**
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Environment Variables

For the Gemini API key, pass it at build time:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Or set it directly in the app's Settings section at runtime.

---

## 🔗 Device Connection Flow

```
1. Power on ESP32 AgriGuard Robot
2. Open app → "Add Device"
3. App scans via BLE → discovers "AgriGuard_Robot"
4. Connect → app fetches available WiFi networks from ESP32
5. User selects network + enters password
6. App sends credentials over BLE (chunked, 20-byte packets)
7. ESP32 connects to WiFi → writes online=true to Firebase
8. App detects online status → device saved under user's profile
9. Full dashboard access unlocked ✅
```

---

## 🤖 AI & Machine Learning

### Plant Classification API

The classification backend is a **FastAPI** service deployed on Railway:

- `POST /classify/task1` — Wheat disease classification
- `POST /classify/task2` — Tomato disease classification  
- `POST /classify/both` — Auto-select highest confidence result

**Confidence threshold:** Results below 35% trigger a "Plant not detected" warning, prompting the user to retake the photo.

### Gemini AI Integration

AgriGuard AI uses **Gemini 2.5 Flash** with:

- Strict agricultural topic routing (off-topic queries are gracefully rejected)
- Classification result injected as ground truth into the system prompt
- Low temperature (0.1) to prevent hallucination of medical/agricultural facts
- Offline fallback with a rich local expert database covering treatments, prevention, and chemical controls

---

## 📡 Firebase Structure

```
Firebase Realtime Database
├── Users/
│   └── {userId}/
│       ├── device_mac: "78:1C:3C:B8:8C:8A"
│       ├── linked_at: timestamp
│       ├── lastActiveSessionId: "session_..."
│       └── chats/
│           └── {sessionId}/
│               ├── id, title, cropType, diagnosisResult
│               ├── confidence, imageUrl, timestamp
│               └── messages/
│                   └── {messageId}/
│                       ├── id, senderType, text
│                       ├── timestamp, isFavorite
│
└── Devices/
    └── {MAC_ADDRESS}/
        ├── online: true/false
        ├── wifi_ssid: "MyFarm_WiFi"
        ├── cmd: "FORWARD" | "BACKWARD" | "LEFT" | "RIGHT" | "STOP"
        ├── status: 0 | 1
        ├── configured_at: timestamp
        └── gps/
            ├── lat: 30.0444
            └── lng: 31.2357
```

---

## 🗺️ Roadmap

- [ ] **Multi-device support** — manage multiple robots per farm
- [ ] **Automated field mapping** — robot autonomously maps and surveys the entire field
- [ ] **Push notifications** — critical alerts delivered even when app is closed
- [ ] **Historical data charts** — NPK trends over days/weeks/months
- [ ] **Crop calendar** — planting and treatment scheduling
- [ ] **Dark mode** — full theme implementation
- [ ] **Offline mode** — cached dashboard data for low-connectivity areas
- [ ] **Web dashboard** — farmer overview panel for desktop

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

<div align="center">

Made with 💚 for farmers everywhere

**AgriGuard** — *Grow smarter. Farm better.*

</div>
