# 🛒 Shalimar Store v4.1.0 — Major Feature Release

### 📅 Release Date: November 7, 2026
### 🏬 Md. Jamil General Store (Since 1988), Alamganj, Ashok Rajpath, Patna - 800007

---

## 🌟 Highlights of this Release

### ✨ 1. Google Gemini Pro AI Hub
- **Interactive Step-by-Step API Key Setup:** Added visual 4-step tutorial card in Admin Side Panel guiding the owner to acquire and paste their Gemini Pro API Key from Google AI Studio.
- **Live Connection Ping:** Verifies the API key in real time against `gemini-1.5-pro` with live status banners (`🟢 Connected & Active` / `🔴 Verification Error`).
- **📸 Vision "Photo-to-Product" Form Auto-Fill:** 1-tap snap of any grocery package automatically extracts Name, Category, Pack Unit, MRP, and Description directly into the Add/Edit Product form.
- **📢 Automated Customer Push Notifications:** Gemini crafts tailored, high-converting Hinglish/English deals and festive announcements. Broadcasts are synced to Firestore `/broadcast_notifications` and trigger heads-up push alerts across all registered customer devices.
- **🧾 Parchi & WhatsApp List Decoder:** Instantly parses handwritten customer parchis and unstructured WhatsApp grocery lists into itemized bills.
- **📊 Smart Reorder Advisory:** Forecasts high-demand and out-of-stock items in the Analytics drawer.

### 📲 2. Instant App Sharing with QR Code (arm64-v8a)
- Available in both **Admin Side Panel** and **Customer Profile & Settings Dialog**.
- Generates an instant, offline, high-contrast QR code targeting the latest stable Android `arm64-v8a` APK release.
- Includes 1-tap **"Share via WhatsApp"** button with formatted message and direct APK link.
- Includes 1-tap **"Copy Download Link"** and direct link to GitHub Releases.

### 📊 3. Unified Admin Side Panel (Drawer)
- Consolidates all administrative operations into a sleek, clean 4-tab side drawer, keeping the main dashboard distraction-free:
  - **Tab 1 (Insights & CRM):** Registered customer directory with 1-tap WhatsApp chat/call, WhatsApp order receipt logs, and inventory health valuation.
  - **Tab 2 (Gemini AI Hub):** API Key setup, connection verification, feature toggles, and AI push notifications copywriter.
  - **Tab 3 (Share App):** Instant QR Code & direct APK sharing tools.
  - **Tab 4 (Settings):** Store timings, customer delivery banner notice, and OTA update checks.
- **Multi-Select Batch Operations:** Long-press enters Selection Mode to batch delete or batch reassign categories.

### 🔍 4. Full-Screen Pinch-to-Zoom Image Viewer Everywhere
- Reusable `FullScreenImageViewer` modal supporting 1x to 5x pinch zoom and double-tap zoom across:
  - Customer Product Details multi-image gallery
  - Customer Shopping Cart item thumbnails
  - Storefront Heritage historical photos
  - Admin Dashboard 50x50 product thumbnails
  - Add/Edit Product photo previews

### 🔒 5. Persistent Sessions (Zero Auto-Logout)
- Active Admin and Customer sessions are preserved permanently across app updates and daily usage until explicit sign-out.

### 📝 6. Option A Description Integrity
- Only custom-entered descriptions appear in customer product details; empty descriptions remain completely hidden without boilerplate text.

---

## 📦 APK Downloads

| Package | Architecture | Description |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-arm64-v8a-release.apk)** | `arm64-v8a` | **Recommended:** Modern 64-bit Android smartphones |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-armeabi-v7a-release.apk)** | `armeabi-v7a` | 32-bit legacy Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-x86_64-release.apk)** | `x86_64` | Android Emulators & Chromebooks |
