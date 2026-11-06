# 🛒 Shalimar Store v3.4.1 Release Notes

**Shalimar Store (Est. 1988) — Official Mobile Application**  
*Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007, Bihar*

---

## 🚀 What's New in Version 3.4.1

### 🔄 OTA Update Fix
- Version bumped to **v3.4.1** so OTA updates now trigger correctly
- Previous v3.4.0 matched installed version, so no update banner appeared
- Now: any device on v3.4.0 or older will see the update notification

### 🔄 Real-Time Cloud Sync
- Admin changes instantly appear on all customer phones (< 1 second)
- Powered by Firebase Firestore (`products` collection)
- Offline-first: customers browse last known catalogue when network drops
- Deletions propagate too (product removed → gone on all devices)

### 🔐 Persistent Admin Login
- Owner signs in once (`Shalimar@1988` / `Shal1mar@1988#`)
- 7-day session survives app restarts
- Automatic Firebase Auth session for Firestore write access

### 🚫 Single Active Admin Session
- Only one device holds admin role at a time
- New login on another device auto-logs previous device out
- Takeover detection via `admin_sessions/active` Firestore doc

### 🖼️ Supabase Storage Images
- Photos uploaded to Supabase Storage (1 GB free tier)
- Public bucket `product-images` with RLS
- URL saved in product document → all customers see the same image

### 📦 Clean Production Launch
- Zero bundled demo products
- Empty store = ready for real inventory
- Auto-clears old cache when app version changes

---

## 📦 Installation

| Download | Architecture | Recommended For |
| :--- | :--- | :--- |
| 📲 **app-arm64-v8a-release.apk** | `arm64-v8a` | Modern Android phones (2018+) — **Recommended** |
| 📲 **app-armeabi-v7a-release.apk** | `armeabi-v7a` | Older 32-bit Android phones |
| 📲 **app-x86_64-release.apk** | `x86_64` | Android Emulators & Chromebooks |

---

## 🛠️ Developer Notes

- Build triggered: push to `main` branch
- CI: GitHub Actions (ubuntu-latest, Flutter 3.x)
- Release created: `v3.4.1` with above release notes

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*