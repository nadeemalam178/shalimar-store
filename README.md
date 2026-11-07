<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v4.2.1)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v4.2.1-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Gemini%203.6%20Flash-AI%20Hub%20Active-8E24AA?logo=google&logoColor=white" alt="Gemini 3.6 Flash AI" />
  <img src="https://img.shields.io/badge/OTA-Startup%20Auto%20Prompt-brightgreen" alt="Startup OTA" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Supabase-Storage%20Images-3ECF8E?logo=supabase&logoColor=white" alt="Supabase Storage" />
  <img src="https://img.shields.io/badge/QR%20Code-Instant%20App%20Sharing-blue" alt="QR Code" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
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

## 🚀 What's New in v4.2.1

### 🧠 Google Gemini 3.6 Flash AI Upgrade
- **Cutting-Edge Flash Model:** Upgraded the AI core to `gemini-3.6-flash`, providing near-instant responses, ultra-low latency, and enhanced vision reasoning for "Photo-to-Product" form auto-fill.
- **Multi-Tier Cascade Resilience:** Seamless automatic fallback across the Flash model family (`gemini-3.6-flash` -> `gemini-2.5-flash` -> `gemini-2.0-flash` -> `gemini-1.5-flash`) ensuring 100% availability.

### ⚡ Automatic Startup OTA Update Prompt
- **Cold-Start Check on Launch:** Automatically checks for GitHub releases when opening the app, whether on the **Login Screen** or the **Customer Main Screen**.
- **Instant In-App Update Modal:** Displays `InAppUpdateDialog` with changelog and direct 1-tap download & install of the architecture-matching APK (`arm64-v8a`).

### 🛍️ Customer Product Cards Overhaul & Smart Kirana Descriptions
- **60% Image Flex Ratio:** Product photos occupy 60% of the card height (`flex: 6`), giving products a rich, expansive, modern grocery storefront appearance.
- **Contextual Grocery Taglines:** Dynamic kirana subtitle taglines on cards (e.g., *"Chakki Fresh Atta • 100% Whole Wheat"*, *"Premium Basmati & Pulav Rice"*, *"Pure Desi Danedar Ghee"*, *"Authentic Indian Spice"*).
- **Smart Description Fallback:** Generates authentic Hindi/English product descriptions based on name and category whenever custom descriptions are left blank.

### 🧹 Streamlined Admin Dashboard Top Bar
- Removed clutter and overlapping icon buttons from the Admin AppBar.
- Fast access to Storefront View, Gemini 3.6 Flash AI Hub drawer, and a clean overflow menu for Store Categories, Settings, and Sign Out.

### 🔒 Admin Mode Context Constraint
- Top-left profile side drawer is constrained in Admin mode so customer details never interfere with store management.

### 🔄 Fresh Session Migration (Clean Sign-Out on Update)
- Upgrading automatically performs a clean sign-out migration across Admin and Customer sessions to ensure a fresh, consistent local state.

### 👥 Customer Directory Reset & Owner Exclusion
- Fixed customer count metrics to exclude the store owner (`nadeemalam178@gmail.com`).
- Added a 1-tap **"Reset Directory (Reset to 0)"** button in the Admin Side Panel.

---

## ✨ Flagship Capabilities

- **✨ Google Gemini 3.6 Flash AI Hub:** Vision "Photo-to-Product" form auto-fill, automated customer push notifications via Firestore, parchi/WhatsApp list decoder, and smart reordering advisor.
- **📲 Instant App Sharing with QR Code (arm64-v8a):** Offline high-contrast QR code and 1-tap WhatsApp sharing in both Admin Drawer and Customer Profile.
- **🔍 Full-Screen Pinch-to-Zoom Image Viewer:** Pinch zoom (1x to 5x) across customer galleries, shopping carts, storefront photos, and admin dashboards.
- **☁️ Google Firebase Firestore Sync:** Real-time bi-directional catalog synchronization between store owner and customer devices.
- **⚡ Zero-Fee UPI & WhatsApp Orders:** Instant WhatsApp grocery dispatch and direct zero-gateway-fee UPI QR payments.

---

## 📦 APK Downloads & Architecture

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-arm64-v8a-release.apk)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-armeabi-v7a-release.apk)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-x86_64-release.apk)** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
