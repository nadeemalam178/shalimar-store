<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v3.2.4)</h1>

<p align="center">
  <b>Official Dual-Mode Kirana & General Store Mobile Application</b><br>
  <i>Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v3.2.4-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Auth-Email%20%7C%20Google%20Sign--In%20Active-blue" alt="Authentication" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Typography-Plus%20Jakarta%20Sans-indigo" alt="Plus Jakarta Sans" />
  <img src="https://img.shields.io/badge/Theme-AMOLED%20Dark%20%26%20Light-darkgreen" alt="Dynamic AMOLED Theme" />
  <img src="https://img.shields.io/badge/OTA-arm64--v8a%20Direct%20OTA-brightgreen" alt="OTA Updates" />
  <img src="https://img.shields.io/badge/Android-ARM64%20(v1--v4%20Signed)-success" alt="Android" />
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

## 🚀 What's New in v3.2.4 (Resolved Google Sign-In Hang & GitHub Actions Automated CI/CD)

- ⚡ **Fixed Google Sign-In Hang**:
  - Eliminated the race condition caused by pre-emptive `signOut()` before `signIn()` that hung Google Play Services platform channels.
  - Removed unrecognized `'profile'` scope string that caused Google Play Services to stall.
  - Added strict timeouts (45s Google Sign-In, 20s token retrieval, 5s Firestore profile sync) with instant UI unfreezing.
  - Non-blocking Firestore profile synchronization so customer catalog navigation happens instantaneously.
- 🤖 **Automated GitHub Actions CI/CD Pipeline**:
  - Securely decoded production release keystore from repository secrets.
  - Automated testing, building, and publishing dedicated `arm64-v8a` release directly on GitHub.

---

## 🚀 What's New in v3.2.2 (Pure ARM64 OTA Distribution & Google Auth Diagnostics)

- 📦 **Pure `arm64-v8a` Single-Asset Release:**
  - Releases are distributed with dedicated `app-arm64-v8a-release.apk` asset, ensuring 100% compatibility across older and newer app installs with zero architecture conflict.
- 🔑 **Google Sign-In Diagnostics & 1-Tap SHA-1 Helper:**
  - Added clean exception handling and diagnostic modal with 1-tap clipboard copy for the release keystore SHA-1 fingerprint (`9B:2E:6B:EC:AB:AA:AD:2F:02:8B:81:41:76:EC:D2:C2:BA:EB:5E:F4`).
  - Seamless fallback messaging highlighting immediate Email & Password login.
- 👤 **Session State Restoration:**
  - Cold startup now instantly restores current Firebase Auth credentials into the customer profile model.

---

## 🚀 What's New in v3.2.1 (Architecture-Aware Direct OTA & Persistent Update Banner)

- ⚡ **Device-Architecture-Aware OTA (Zero Installation Errors):**
  - Resolves CPU architecture mismatch on physical Android smartphones (`arm64-v8a` / `armeabi-v7a`).
  - Runtime ABI inspection via `dart:ffi Abi.current()`.
  - Always downloads the exact matching APK (`app-arm64-v8a-release.apk` on 64-bit ARM hardware, `app-armeabi-v7a-release.apk` on 32-bit ARM hardware), preventing `x86_64` emulator builds from being downloaded on phones.
  - Verified architecture badge displayed inside the dialog: `Target ABI: arm64-v8a (Verified for this phone)`.
- 📖 **First-Time Center Popup with Full Changelog:**
  - When an update is detected, the dialog automatically opens in the middle of the screen.
  - Customers can read the complete changelog and release notes before downloading.
  - Clean "Later" and "Update Now" action buttons.
- 📌 **Persistent Top Update Banner:**
  - The update banner stays persistently pinned at the top of the catalog until updated.
  - Dismissing the middle changelog leaves the top banner active so customers can tap to view the changelog and install the update at any time.

---

## 🔐 What's New in v3.2.0 (Compulsory Customer Registration & Google Auth)

- 🔐 **Compulsory Customer Authentication (Zero Guest Access):**
  - Unauthenticated access to the catalog is blocked. Customers must register or sign in to browse and order.
  - Persistent sessions: customers stay signed in across device restarts.
  - 1-tap Sign Out flow built into customer profile dialog.
- ⚡ **Dual Authentication Providers:**
  - **Full Name, Email & Password Registration:** Easy registration form with real-time Firebase profile creation.
  - **Continue with Google:** 1-tap Google Sign-In with automatic name, email, and photo syncing.
  - **Password Recovery:** Direct password reset email delivery.
- ☁️ **Customer Database (`users/{uid}`):**
  - Auto-syncs registered customer records to Cloud Firestore.
  - Protected by strict Firestore Security Rules (`firestore.rules`).
- 🌓 **AMOLED Dark Mode Overhaul for Entry Screens:**
  - Splash screen rebuilt with `#121212` background and zero blinding white flashes.
  - Onboarding carousel and Login screens natively designed for AMOLED dark mode.
- 🛡️ **Owner Hardening:**
  - Purged hardcoded admin IDs and hashes from source code; bound to verified owner identity (`AppConstants.ownerEmail`).

---

## 📦 What's New in v3.1.0

- 📲 **In-App Direct OTA Updates:** Updates download directly inside the app with a streaming byte progress bar and automatically trigger Android's native package installer (`open_filex`). No external browser or Chrome redirects required.
- ☁️ **Google Firebase Cloud Sync:** Full integration with Google Firebase Firestore (`shalimar-store`) on the Free Spark Tier. Products, stock levels, and prices sync in real time across owner and customer phones.
- 🔔 **Dual-Tier Push & Local Notification Engine:**
  - **"🔔 Notify Me When in Stock":** Out-of-stock items feature an interactive restock alert button subscribing customers to `restock_<productId>`.
  - **Automatic Restock Alerts:** Toggling an item back in stock in the Admin Panel immediately fires notifications to waiting customers.
  - **Local Order Dispatch Alerts:** Native heads-up notifications confirm WhatsApp orders instantly.
  - **Store Broadcast Announcements:** Topic subscription (`store_broadcast`) for deals and festival updates.
- 🌓 **Complete AMOLED Dark Theme Overhaul:** All customer tabs, navigation docks, floating cart bars, search bars, and admin panels rewritten using adaptive semantic tokens for true `#121212` / `#1E1E1E` AMOLED aesthetics.
- 🧹 **Production Admin Hardening:** Completely removed the demo "Quick-Loader" from Admin Dashboard so only real inventory is maintained.

---

## ✨ Features from v3.0.0

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
