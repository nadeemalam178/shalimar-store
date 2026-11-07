<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988 (v4.0.0)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v4.0.0-crimson" alt="Version" />
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

## 🚀 What's New in v4.0.0 (Milestone Release)

### 🧹 Fresh Catalogue Directory & Clean Session Reset
- Upgrading to v4.0.0 clears all obsolete local catalogue caches, providing an empty product directory so the store owner can add genuine store inventory freshly.
- Cleanly resets and logs out all existing sessions (both admin and customer) so everyone starts on a clean slate.

### 🛡️ Enterprise Security & Hardened Firestore Rules
- **Owner-Only Product Writes:** `/products/{productId}` allows real-time public read, but write/delete permissions are strictly restricted to the verified Store Owner.
- **Customer Privacy Protection:** Customer profiles (`/users/{userId}`) are private to their respective owners; unauthorized PII scraping and cross-user updates are blocked.
- **Role Tampering Prevention:** Rules strictly prevent customers from elevating their account role to `'owner'`.
- **Elimination of Hardcoded Passwords:** Removed all plaintext credentials from client source. Owner logs in authoritatively through Firebase Auth.

### 📸 Samsung Camera LMK Fix & Form Draft Recovery
- Added `android:largeHeap="true"` and configured image compression (1024x1024 @ 80%) to prevent Low Memory Killer crashes on Samsung Galaxy devices.
- Implemented persistent background form drafts: product name, price, MRP, unit, category, and description are safely preserved before opening camera and restored if Android reloads the app.

### 🗂️ Dynamic Category Management & Fallback
- Added `ManageCategoriesDialog` allowing the store owner to add or remove departments directly.
- Deleting an active category automatically reassigns all affected products to `"General"` with zero data loss.

### ⚖️ Standardized Kirana Pack Sizes
- Added standardized unit dropdown (`1 kg`, `500 gm`, `250 gm`, `1 Liter`, `500 ml`, `1 pc`, `1 Packet`, etc.) plus custom unit input for consistent cataloguing.

### 🔍 Hinglish & Colloquial Grocery Search
- Built-in colloquial search dictionary maps common Indian terms (`tel`, `atta`, `dal`, `chawal`, `chai`, `sabun`) directly to English catalogue entries.

### 📦 Out-of-Stock Card Tap Handling
- Fixed touch interception on greyed-out out-of-stock items so customers can tap to view product details, pack size, and description.

### 📲 1-Tap WhatsApp Product Promotional Sharing
- Added 1-tap WhatsApp button in Admin Dashboard generating pre-formatted promotional messages with product title, price, savings, and store link.

### 🖼️ Hardened Supabase Image Pipeline
- Enforces 5 MB file size limit, MIME-type filtering, and binary magic-byte inspection (JPEG, PNG, WebP) to block non-image uploads.
- Automatically cleans up image files in Supabase Storage when products are deleted.

---

## 📦 APK Downloads & Architecture

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **[app-arm64-v8a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **[app-armeabi-v7a-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **[app-x86_64-release.apk](https://github.com/nadeemalam178/Shalimar-Store/releases/latest)** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
