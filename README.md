<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v4.1.0)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v4.1.0-crimson" alt="Version" />
  <img src="https://img.shields.io/badge/Gemini%20Pro-AI%20Hub%20Active-8E24AA?logo=google&logoColor=white" alt="Gemini Pro AI" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Supabase-Storage%20Images-3ECF8E?logo=supabase&logoColor=white" alt="Supabase Storage" />
  <img src="https://img.shields.io/badge/QR%20Code-Instant%20App%20Sharing-blue" alt="QR Code" />
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
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

## 🚀 What's New in v4.1.0 (Major Release)

### ✨ Google Gemini Pro AI Hub
- **Dedicated Step-by-Step Onboarding Guide:** Clear 4-step tutorial in the Admin Side Panel guiding the owner to acquire their Gemini Pro API Key directly from Google AI Studio.
- **Live Connection Ping:** Verifies the API key in real time against Google's Generative Language API (`gemini-1.5-pro`) with clear status indicators.
- **📸 Vision "Photo-to-Product" Auto-Fill:** 1-tap snap of any grocery item automatically fills product name, category, pack size/unit, MRP, and description.
- **📢 Automated Customer Push Notifications:** Gemini crafts engaging Hinglish/English festive deals, daily staples discounts, and fresh stock alerts. Broadcasts are saved to Firestore `/broadcast_notifications` and trigger real-time heads-up push notifications on all registered customer devices.
- **🧾 Parchi & WhatsApp List Decoder:** Seamless parsing of handwritten grocery chits and unstructured WhatsApp grocery lists.

### 📲 Instant App Sharing with QR Code (arm64-v8a)
- Available in both **Admin Side Panel** and **Customer Profile & Settings**.
- Generates an offline high-contrast QR code targeting the latest stable release: `https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-arm64-v8a-release.apk`.
- Includes 1-tap **"Share via WhatsApp"** and **"Copy Download Link"** buttons.

### 📊 Unified Admin Side Panel (Drawer)
- Consolidates Store Insights & CRM, Gemini Pro AI Hub, App Sharing QR, and Store Settings into 4 organized tabs, keeping the main dashboard clean and clutter-free.
- **Customer CRM Directory:** Real-time customer list with 1-tap WhatsApp chat, direct phone call, and delivery addresses.
- **WhatsApp Order Intelligence:** Tracks customer order submissions, estimated store revenue, and recent receipts.
- **Batch Product Operations:** Long-press multi-select to batch delete or batch move products to any department.

### 🔍 Full-Screen Pinch-to-Zoom Image Viewer Everywhere
- Reusable `FullScreenImageViewer` modal supporting 1x to 5x pinch zoom and double-tap zoom across:
  - Customer Product Detail screen (multi-image gallery)
  - Customer Shopping Cart item thumbnails
  - Store Heritage storefront photos
  - Admin Dashboard 50x50 product thumbnails
  - Add/Edit Product photo previews

### 🔒 Persistent Sessions (Zero Auto-Logout)
- Active Admin and Customer sessions remain persistently logged in across app updates and daily usage until explicit sign-out.

### 📝 Option A Description Integrity
- Only custom-entered descriptions are shown in customer product details; empty descriptions remain cleanly hidden.

---

## 📦 APK Downloads & Architecture

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
