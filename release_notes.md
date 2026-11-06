# 🛒 Shalimar Store v3.2.5 — Direct Owner Sign-In, Cloud GitHub CI/CD & App Tour

**Shalimar Store (Est. 1988) — Official Mobile Application**  
*Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007, Bihar*

---

### 🚀 What's New in Version 3.2.5:

#### 🔑 Dual-Path Store Owner Authentication
- **Dedicated Store Owner Modal:** Access the owner authentication modal directly with 1 tap from both the customer login screen and the store catalog header.
- **Support for Non-Email Admin ID:** The store owner can sign in using **Admin ID: `Shalimar@1988`** with **Password: `Shal1mar@1988#`**, or via verified owner email (`nadeemalam178@gmail.com`).
- **Smart Form Identifier Routing:** Entering owner credentials directly into the main customer sign-in form now automatically routes to administrative authentication without demanding an `@` email domain format.

#### 📖 On-Demand App Tour & Onboarding
- **Re-Accessible Welcome Tour:** Customers and store managers can re-visit the full 4-slide onboarding presentation anytime by tapping **"App Tour (Intro)"** on the login screen.
- Highlights store heritage (serving Patna since 1988), catalog browsing, cart ordering, and instant WhatsApp dispatch.

#### 🤖 100% Automated GitHub Actions Cloud CI/CD
- **Zero Local Build Dependencies:** Release APKs are compiled, tested, signed, and published 100% via GitHub Actions on `ubuntu-latest`.
- **Sanitized Keystore Pipeline:** Cleans base64 decoding whitespace and outputs standard properties via POSIX `printf` for guaranteed signing without Gradle parse errors.
- **Full Split-per-ABI Distribution:** Every release publishes dedicated binaries for modern 64-bit phones, older 32-bit devices, and x86_64 emulators.

---

### 📦 Split-per-ABI APK Downloads:

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.5/app-arm64-v8a-release.apk)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.5/app-armeabi-v7a-release.apk)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.5/app-x86_64-release.apk)** | `x86_64` | Android Emulators & Chromebooks |

---

### ⚡ Previous Highlights (v3.2.0 – v3.2.3):
- **Device-Architecture-Aware OTA:** In-app updater automatically queries runtime ABI and downloads the exact binary match with live streaming byte progress and direct installer launch.
- **Compulsory Customer Authentication:** Firebase Email/Password & Google Sign-In with customer records synchronized to Cloud Firestore (`users/{uid}`).
- **True AMOLED Theme:** Deep `#121212` backgrounds across splash, login, catalog, cart, and admin screens with zero white flashes.
- **Real-Time Inventory Sync:** Live Firebase cloud synchronization for stock counts, item availability, and restock notifications.
