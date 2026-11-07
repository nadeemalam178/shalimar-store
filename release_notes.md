# 🛒 Shalimar Store v3.4.5 Release Notes

**Shalimar Store (Est. 1988) — Official Mobile Application**  
*Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007, Bihar*

---

## 🚀 What's New in Version 3.4.5

### 🚫 Complete Removal of Dummy Catalog Data
- Removed the automatic fallback that restored the 24 demo Kirana items from local assets.
- The app now strictly mirrors the live Cloud inventory: what the owner enters is what everyone sees, with zero ghost items.

### 🖼️ Seamless Supabase Photo Uploads
- Resolved the image upload flow so newly captured/picked product images upload directly to Supabase Storage before updating Firestore.
- Public image URLs load on both Admin and Customer devices immediately.

### 🎨 Out-of-Stock Rendering & Visual Glitch Fix
- Fixed the Flutter render tree issue where marking an item "Out of Stock" caused other product cards to lose their background colors or text data.
- Out of stock now cleanly dims the product without breaking UI layout or adjacent items.

### 🔔 Smart Customer-Only Stock Notifications
- Store owners no longer receive local notifications when changing stock states in the Admin Dashboard.
- Customer phones receive restock and out-of-stock alerts only if the item is in their **Cart**, **Favorites**, or restock alerts.

### 👑 Streamlined Owner Experience
- Logging in as Store Owner bypasses customer registration straight into Admin Management.
- Dedicated "Switch to Customer View" button lets the owner preview the store with `"Welcome, Owner 👑"`.
- Regular customers will never see an "Owner" button or admin trigger.

### 🛡️ Security Hardening
- Plaintext password fallback strings have been purged from the client source code.
- Admin authentication is verified using SHA-256 cryptographic hashes.
- Single-admin enforcement prevents multiple simultaneous admin sessions using a 90-second heartbeat monitor.

---

## 📦 Installation APKs

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **app-arm64-v8a-release.apk** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **app-armeabi-v7a-release.apk** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **app-x86_64-release.apk** | `x86_64` | Android Emulators & Chromebooks |

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*
