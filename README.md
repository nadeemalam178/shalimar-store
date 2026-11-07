<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v3.4.5)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v3.4.5-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Supabase-Storage%20Images-3ECF8E?logo=supabase&logoColor=white" alt="Supabase Storage" />
  <img src="https://img.shields.io/badge/Auth-Email%20%7C%20Google%20Sign--In%20Active-blue" alt="Authentication" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Theme-AMOLED%20Dark%20%26%20Light-darkgreen" alt="AMOLED Theme" />
  <img src="https://img.shields.io/badge/OTA-arm64--v8a%20Direct%20OTA-brightgreen" alt="OTA Updates" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## 🏬 Real Store Heritage

<p align="center">
  <img src="assets/images/store_front.jpg" width="550" alt="Store Front" style="border-radius: 16px; box-shadow: 0 4px 14px rgba(0,0,0,0.2);" />
  <br>
  <i><b>Md. Jamil General Store (Shalimar G. Store)</b> — Alamganj Main Road, Ashok Rajpath, Patna - 800007, Bihar</i>
</p>

Established in **1988** by Mohammad Jamil, **Shalimar General Store** has been a beloved neighborhood landmark for over **35+ years** in Patna.

---

## 🚀 What's New in v3.4.5

### 🚫 Complete Elimination of Dummy Products
- Purged all hardcoded fallback sample data. The app now reflects **only 100% real products** created by the store owner in Firestore.
- Fixed catalog sync so old asset data never resurrects or gets merged after app restarts or updates.

### 🖼️ Supabase Photo Uploads & Instant Cloud Sync
- Product images uploaded from Admin Camera/Gallery are processed and uploaded to the public Supabase `product-images` bucket.
- High-res public HTTPS URLs are saved to Firestore, streaming seamlessly to all customer devices in real-time.

### 🎨 Clean Out-of-Stock Rendering (Bug Fix)
- Fixed the Flutter render tree glitch where toggling an item out of stock caused neighboring card backgrounds or details to disappear.
- Replaced destructive saturation filters with clean, native badge overlays and greyed-out state styling.

### 🔔 Smart Targeted Notifications
- Admin toggles no longer trigger local push notifications on the store owner's device.
- Customer phones receive stock notifications only for items present in their **Cart**, **Favorites**, or restock subscriptions.

### 👑 Direct Admin Flow & Customer Store Preview
- Logging in as Store Owner navigates straight into the Admin Dashboard.
- Tapping **"Switch to Customer View"** lands on the live customer preview showing `"Welcome, Owner 👑"`.
- Regular customer screens strictly hide the Owner shortcut button.

### 🛡️ Enhanced Security Hardening
- Removed all plaintext master password fallbacks from source code; authentication now uses SHA-256 cryptographic hashes.
- Single-admin enforcement prevents multiple simultaneous admin sessions using a Firestore heartbeat check.

---

## 📦 APK Downloads & Architecture

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/shalimar-store/releases/latest)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/shalimar-store/releases/latest)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/shalimar-store/releases/latest)** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
