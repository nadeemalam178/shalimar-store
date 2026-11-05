<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v3.0.0)</h1>

<p align="center">
  <b>Official Dual-Mode Kirana & General Store Mobile Application</b><br>
  <i>Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v3.0.0-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Typography-Plus%20Jakarta%20Sans-indigo" alt="Plus Jakarta Sans" />
  <img src="https://img.shields.io/badge/Theme-Dynamic%20AMOLED%20System-darkgreen" alt="Dynamic AMOLED Theme" />
  <img src="https://img.shields.io/badge/OTA-GitHub%20Releases%20Live-brightgreen" alt="OTA Updates" />
  <img src="https://img.shields.io/badge/Architecture-Offline--First%20Clean-emerald" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/Android-Split%20ABI%20(v1--v4%20Signed)-success" alt="Android" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## 🏬 Real Store Heritage

<p align="center">
  <img src="assets/images/store_front.jpg" width="550" alt="Md. Jamil General Store - Shalimar Store Front, Alamganj, Patna" style="border-radius: 16px; box-shadow: 0 4px 14px rgba(0,0,0,0.2);" />
  <br>
  <i><b>Md. Jamil General Store (Shalimar G. Store)</b> — Alamganj Main Road, Ashok Rajpath, Patna - 800007, Bihar</i>
</p>

Established in **1988** by Mohammad Jamil, **Shalimar General Store** has been a beloved neighborhood landmark for over **35+ years** in Patna. Serving authentic daily essentials, pure mustard oils, premium basmati rice, spices, lentils, fresh dairy, and household goods with personalized doorstep care.

---

## ✨ What's New in v3.0.0

- 🔍 **Interactive Product Detail View:** Tap any product card to expand into an immersive, dedicated product view featuring smooth `Hero` animations.
- 🖼️ **Multi-Image Swipeable Carousel:** Explore items from every angle with a touch-friendly `PageView` carousel and real-time dot indicators.
- 💡 **"More Like This" & "More For You" Recommendations:** Smart in-category and cross-category horizontal recommendation carousels to help customers discover matching items and household staples.
- 🔤 **Plus Jakarta Sans Typography:** Integrated Google Font **Plus Jakarta Sans** for a modern, crisp, high-clarity retail feel across light and dark themes.
- 🌓 **Dynamic AMOLED System Theme:** Seamlessly adapts to Android OS dark/light mode (`ThemeMode.system`) without any manual switches. True AMOLED `#121212` canvas with gold and emerald accents.
- ⚡ **Lightweight Performance & Memory Optimization:**
  - Constrained image decoders (`cacheWidth: 350, cacheHeight: 350`) prevent OOM spikes and slash bitmap RAM by ~85%.
  - Softened frosted glass blur from sigma 12 to 4 with tinted backdrop, preserving a solid 60 FPS on budget devices.
  - Isolated product cards with `RepaintBoundary` to minimize layout redraws.
- ⌨️ **Gliding Keyboard Ergonomics:** Admin login dialog floats smoothly upward when the on-screen keyboard opens, keeping password fields and buttons visible.
- 🔐 **Rotated Owner Credentials:** Rotated security credentials verified via SHA-256 hash (Admin ID: `Shalimar@1988`).
- 📡 **Live GitHub Releases OTA Updates:** Users running older versions receive an instant in-app update banner with 1-tap download.

---

## 📱 App Experience & Architecture

```
┌────────────────────────────────────────────────────────┐
│  [Logo] Welcome, Nadeem 👋               [Admin/Owner] │
├────────────────────────────────────────────────────────┤
│  🔍 [Search 1,000+ items, brand, category...] (PINNED) │
├────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🛒 SHALIMAR STORE — Since 1988 (Tap for Photos)  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  [All (52)] [Atta & Rice (12)] [Oils (8)] [Dairy (6)]   │
│                                                        │
│  ┌───────────────────┐      ┌───────────────────┐      │
│  │ Aashirvaad Atta   │      │ Fortune Sunlite   │      │
│  │ 10 kg • ₹445 ₹490 │      │ 1 L • ₹135 ₹150   │      │
│  │    [ -  1  + ]    │      │     [ + ADD ]     │      │
│  └───────────────────┘      └───────────────────┘      │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🛒 3 Items | ₹490          View Cart & Order ➔     │ │ <── Floating Cart Deck
│ ├────────────────────────────────────────────────────┤ │
│ │  ❤️ Favorites        🏠 Store          🛍️ Cart     │ │ <── Modern Bottom Dock
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

### 📦 Managing 1,000+ Items & Database Performance

| Metric | Implementation & Optimization |
| :--- | :--- |
| **Storage Engine** | Offline-first persistent JSON storage backed by `SharedPreferences` + bundled `standard_catalogue.json`. |
| **Viewport Virtualization** | Uses Flutter's `SliverGrid` and `SliverList.builder` delegate. Regardless of whether there are 50 or 5,000 products, **only ~6 to 8 items visible on screen are kept in active GPU/RAM memory**. |
| **Frame Rate** | Constant 60 FPS smooth scrolling with zero lag or garbage collection spikes. |
| **Image Memory Caching** | Downscaled decoded raster buffers (`cacheWidth: 350`, `cacheHeight: 350`) saving ~85% RAM. |
| **Search Engine** | Real-time multi-attribute filtering across product name, category, and units. |

---

## 📲 Download & Installation

Optimized **Split-per-ABI APKs** (~15–20 MB) signed with APK Signature Scheme v1, v2, v3, and v4:

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[Download app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.0.0/app-arm64-v8a-release.apk)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[Download app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.0.0/app-armeabi-v7a-release.apk)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[Download app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.0.0/app-x86_64-release.apk)** | `x86_64` | Android Emulators & Chromebooks |

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Channel stable, Material 3)
- **Language:** Dart 3.13+
- **Typography:** Google Fonts (`Plus Jakarta Sans`)
- **Theme:** Dynamic AMOLED System Theme (`ThemeMode.system`)
- **State Management:** Provider Architecture (`ChangeNotifier`)
- **Persistence:** `shared_preferences`, Offline Asset JSON
- **Hardware Integration:** `image_picker` (Camera & Gallery)
- **Security:** Cryptographic SHA-256 Admin Authentication
- **External Communication:** Direct WhatsApp API URI dispatch & UPI deep linking

---

## 👨‍💼 Contact & Store Information

- **Store:** Md. Jamil General Store (Shalimar Store, Est. 1988)
- **Address:** Alamganj Main Road, Ashok Raj Path, Patna - 800007, Bihar
- **Owner Phone / WhatsApp:** +91 7488151683
- **Official UPI ID:** `7488151683@upi`
- **Developer:** [Nadeem Alam](https://github.com/nadeemalam178)
