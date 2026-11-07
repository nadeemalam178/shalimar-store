# 🛒 Shalimar Store v4.2.1 — Google Gemini 3.6 Flash Upgrade & Performance Boost

### 📅 Release Date: November 7, 2026
### 🏬 Md. Jamil General Store (Since 1988), Alamganj, Ashok Rajpath, Patna - 800007

---

## 🌟 What's New in v4.2.1

### 🧠 1. Google Gemini 3.6 Flash AI Core Upgrade
- **Frontier Flash Intelligence:** Upgraded the AI core to **Google Gemini 3.6 Flash** (`gemini-3.6-flash`), providing sub-second vision inference, near-instant copy generation, and superior multimodal precision.
- **📸 1-Tap Photo-to-Product Acceleration:** Snapping grocery photos now auto-fills product name, category, pack unit, MRP, price, and description up to **3x faster**.
- **Multi-Tier Cascade Resilience:** Robust automatic fallback mechanism (`gemini-3.6-flash` -> `gemini-2.5-flash` -> `gemini-2.0-flash` -> `gemini-1.5-flash`) ensures 100% uptime across all Google AI API accounts and regional tiers.
- **Interactive AI Studio Guide:** Updated Admin Side Panel with live ping verification reflecting the active Gemini 3.6 Flash connection status.

### 🚀 2. Automatic Startup OTA Update Prompt
- **Instant Cold-Start Detection:** As soon as the app opens — whether on the **Login Screen** or already **Logged In** on the Main Catalog — the app instantly queries GitHub Releases for updates.
- **One-Tap In-App Modal:** Directly presents `InAppUpdateDialog` with changelog and a one-tap download button that streams and installs the device-matched `arm64-v8a` APK.
- **Session-Aware Frequency:** Prompts on every fresh app launch when an update is available without repeatedly popping up when switching tabs during an active session.

### 🖼️ 3. Customer Product Cards & Smart Kirana Descriptions
- **60% Image Flex Height:** Product card layout enhanced with a 60/40 ratio (`flex: 6` image, `flex: 5` info) so grocery photos fill the upper card without being squished.
- **Contextual Grocery Taglines:** Dynamic kirana taglines displayed on cards (e.g., *"Chakki Fresh Atta • 100% Whole Wheat"*, *"Premium Basmati & Pulav Rice"*, *"Pure Desi Danedar Ghee"*, *"Authentic Indian Spice"*).
- **Smart Product Details Fallback:** When a product doesn't have a custom description, `ProductDescriptionHelper` automatically generates a clean, mouthwatering Hindi/English grocery description based on its name and category.

### 🧹 4. Streamlined Admin Dashboard Header
- **Clutter-Free Top Row:** Completely overhauled the Admin Dashboard AppBar, removing crowded and overlapping icon buttons.
- **Clean Action Architecture:** Fast access to **Customer Storefront** (`Icons.storefront_rounded`), **Gemini AI Hub** (`Icons.dashboard_customize_rounded`), and a clean 3-dot overflow menu for **Category Management**, **Store Settings**, and **Secure Sign Out**.

### 🔒 5. Admin Mode Top-Left Constraint
- Prevents accidental customer profile popups when operating in Store Owner / Admin mode.
- Top-left profile trigger is active exclusively in Customer browsing mode.

### 🔄 6. Fresh Migration (Clean Sign-Out on Update)
- First launch automatically performs a clean sign-out migration for both Admin and Customer sessions so all users start fresh.

### 👥 7. Customer Directory Reset & Owner Exclusion
- Fixed customer count metrics in the Admin Side Panel to strictly exclude the store owner (`nadeemalam178@gmail.com`).
- Added a 1-tap **"Reset Directory (Reset to 0)"** action in the Admin Drawer for instantaneous customer list cleanup.

---

## 📦 APK Downloads

| Package | Architecture | Description |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-arm64-v8a-release.apk)** | `arm64-v8a` | **Recommended:** Modern 64-bit Android smartphones (95%+ devices) |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-armeabi-v7a-release.apk)** | `armeabi-v7a` | 32-bit legacy Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-x86_64-release.apk)** | `x86_64` | Android Emulators & Chromebooks |
