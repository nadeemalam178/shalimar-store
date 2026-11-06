# 🛒 Shalimar Store v3.4.0 Release Notes

**Shalimar Store (Est. 1988) — Official Mobile Application**  
*Serving Trust, Quality & Purity on Ashok Raj Path, Alamganj, Patna — 800007, Bihar*

---

## 🚀 What's New in Version 3.4.0

### 🔄 Real-Time Cloud Sync
When the store owner adds, edits, or toggles stock in the admin panel, **every connected customer sees the change within one second**. No separate update required.

- Powered by Firebase Firestore (`products` collection).
- Offline-first: customers browse last known catalogue when network drops.
- Deletions propagate — removed products vanish from all phones.

### 🔐 Persistent Admin Login
The owner logs in **once** and stays logged in across app restarts for up to 7 days.

- Credentials: `Shalimar@1988` + `Shal1mar@1988#` (or owner email).
- Session survives OS updates, phone reboots.
- Automatic Firebase Auth ensures Firestore rules grant write access.

### 🚫 Single Active Admin Session
Only **one device** can be logged in as admin at a time.

- If the owner opens admin on Phone B, Phone A is automatically logged out.
- Takeover detection via `admin_sessions/active` Firestore document.
- Prevents accidental concurrent edits.

### 🖼️ Supabase Storage Images
Product photos are uploaded to Supabase Storage (1 GB free tier).

- Photos live in bucket `product-images/{productId}/`
- Public download URLs stored in product document.
- All customers see the exact same image the owner captured.

### 📦 Clean Production Launch
No bundled demo products — the store starts completely empty.

- Owner builds the real inventory from day one.
- Customer empty state: "Store is being stocked… check back soon."

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
- Release created: `v3.4.0` with above release notes

---

*Built with ❤️ for Md. Jamil General Store (Est. 1988) — Patna, Bihar*