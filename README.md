<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v2.0.0)</h1>

<p align="center">
  <b>Official Dual-Mode Kirana & General Store Mobile Application</b><br>
  <i>Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v2.0.0-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
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

## ✨ What's New in v2.0.0

- ⚡ **Persistent Shopping Cart:** Items placed in the cart remain preserved in local storage across restarts until explicitly ordered on WhatsApp or cleared.
- 🎨 **Animated Splash Screen:** Elegant fade-in and scale animation featuring the circular gold-rimmed Shalimar badge, with a smooth fade-out transition into the store.
- 🔍 **Pinned / Frozen Rounded Search Bar:** Search bar remains permanently pinned at the top while scrolling through 1,000+ items.
- ⌨️ **Dock Jumping Fix:** Bottom deck and floating cart automatically hide while typing in search or forms, preventing any screen clutter.
- ⭕ **Unified Rounded Design Language:** Strict design consistency with 20–30px radiuses on cards, buttons, dialogs, and pill tags.
- 📷 **Direct Camera & Gallery Photo Upload:** Admin can shoot live product photos or pick from the device gallery.
- 📊 **Out-of-Stock Category Breakdown Dashboard:** Interactive management card showing unavailable items grouped by category with 1-tap instant Restock.
- 🏷️ **Dynamic Category Management:** Admin can add new departments on the fly, instantly reflected for all customers without app update.
- 🚀 **Zero-Bloat GitHub Releases OTA Update Banner:** When a new release is published on GitHub, a dismissible banner automatically appears in the app with the changelog and 1-tap download link.
- 🔒 **Confidential Credentials Security:** Default IDs and passwords are never displayed in the app UI, hint text, or text boxes; secured via cryptographic SHA-256 verification.

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
| **Image Memory Caching** | Supports both remote network URLs and offline device files (`File.existsSync()`) with bounded thumbnail caches. |
| **Search Engine** | Real-time multi-attribute filtering across product name, category, and units. |

---

## 📲 Download & Installation

Optimized **Split-per-ABI APKs** (~15–20 MB) signed with APK Signature Scheme v1, v2, v3, and v4:

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[Download arm64-v8a](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v2.0.0/app-arm64-v8a-release.apk)** | `arm64-v8a` (19.8 MB) | Modern Android phones (2018+) — **Recommended** |
| 📲 **[Download armeabi-v7a](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v2.0.0/app-armeabi-v7a-release.apk)** | `armeabi-v7a` (18.1 MB) | Older 32-bit Android phones |
| 📲 **[Download x86_64](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v2.0.0/app-x86_64-release.apk)** | `x86_64` (21.4 MB) | Android Emulators & Chromebooks |

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Channel stable, Material 3)
- **Language:** Dart 3.13+
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
