# 🛒 Shalimar Store v4.0.0 Release Notes

**Shalimar Store (Est. 1988) — Official Mobile Application**  
*Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007, Bihar*

---

## 🚀 What's New in Version 4.0.0 (Milestone Release)

### 🧹 Fresh Catalogue Directory & Clean Session Reset
- Upgrading to v4.0.0 clears all cached catalogue and category items, providing a completely fresh, empty directory so the store owner can add genuine store products from scratch.
- Cleanly logs out all existing admin and customer sessions so everyone starts on a clean slate.

### 🛡️ Production Security Hardening
- **Strict Owner-Only Product Writes:** `/products/{productId}` in Firestore now strictly requires `isOwner()` credentials (`nadeemalam178@gmail.com`). Public writes are completely closed.
- **Customer Privacy:** Customer documents (`/users/{userId}`) are private to their respective UID and the Store Owner. PII scraping and cross-user updates are blocked.
- **Role Elevation Prevention:** Customers cannot modify or elevate their account role to `'owner'`.
- **Eliminated Plaintext Passwords:** Removed all hardcoded credentials from the app binary; owner logs in authoritatively through Firebase Auth.

### 📸 Samsung Camera LMK Crash Fix & Form Draft Recovery
- Added `android:largeHeap="true"` and configured 1024x1024 @ 80% compression to prevent Android Low Memory Killer reloads on Samsung Galaxy devices.
- Added background form draft persistence for product title, price, MRP, unit, category, and description so typed text is never lost when taking photos.

### 🗂️ Dynamic Category Management
- Added `ManageCategoriesDialog` in Admin Dashboard to create or delete categories on the fly.
- Deleting a category automatically and safely reassigns all affected products to `"General"`.

### ⚖️ Standardized Pack-Size Dropdown
- Unified pack-size dropdown (`1 kg`, `500 gm`, `250 gm`, `1 Liter`, `500 ml`, `1 pc`, `1 Packet`, etc.) plus custom unit input.

### 🔍 Hinglish & Colloquial Kirana Search
- Native colloquial search matches Indian terms (`tel`, `atta`, `dal`, `chawal`, `chai`, `sabun`) to catalogue items.

### 📦 Out-of-Stock Card Tap Handling
- Fixed touch interception on greyed-out out-of-stock product cards so customers can tap to view details.

### 📲 1-Tap WhatsApp Promotional Sharing
- Added 1-tap WhatsApp sharing directly from Admin Dashboard with formatted pricing, savings, and store link.

### 🖼️ Hardened Supabase Image Pipeline
- Enforces 5 MB file size limit, MIME-type filtering, and binary magic-byte inspection (JPEG, PNG, WebP) to block non-image uploads.
- Automatically cleans up image files in Supabase Storage when products are deleted.

---

## 📦 Installation APKs

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **app-arm64-v8a-release.apk** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **app-armeabi-v7a-release.apk** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **app-x86_64-release.apk** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
