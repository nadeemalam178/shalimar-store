<p align="center">
  <img src="assets/images/logo.png" width="140" alt="Shalimar Store Logo" />
</p>

<h1 align="center">🛒 Shalimar Store — Since 1988</h1>

<p align="center">
  <b>Modern General Store & Grocery Mobile Application built with Flutter & Dart</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20Layered-emerald" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/State-Provider-orange" alt="Provider" />
  <img src="https://img.shields.io/badge/Android-APK%20Split%20ABI-success" alt="Android" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## 🌟 Overview

**Shalimar Store** is an offline-first, dual-mode general store mobile application designed for local retail and Kirana businesses. It brings traditional neighborhood shopping into the digital era with **zero gateway fees**, **direct WhatsApp ordering**, and an **ID & Password protected owner management panel**.

```
┌────────────────────────────────────────────────────────┐
│  🛍️  SHALIMAR STORE [Logo]                  🔍 [Search]│
├────────────────────────────────────────────────────────┤
│  [Atta & Rice]  [Oils & Ghee]  [Masale]  [Dairy]       │
│                                                        │
│  ┌───────────────────┐      ┌───────────────────┐      │
│  │ Aashirvaad Atta   │      │ Fortune Sunlite   │      │
│  │ 5 kg • ₹245 ₹270  │      │ 1 L • ₹135 ₹150   │      │
│  │    [ -  1  + ]    │      │     [ + ADD ]     │      │
│  └───────────────────┘      └───────────────────┘      │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🛒 3 Items | ₹490          View Cart & Order ➔     │ │ <── Floating Cart Deck
│ ├────────────────────────────────────────────────────┤ │
│ │  ❤️ Favorites        🏠 Store          🛍️ Cart     │ │ <── Modern Dock Navigation
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 🛍️ Customer Experience
- **Interactive First-Time Walkthrough:** Welcomes new customers with a visual 4-slide tour and sets up their personalized customer username.
- **Top Greeting Bar:** Displays customer name (`Welcome, {username} 👋`) with one-tap access to profile, order history, and saved favorites.
- **Modern Bottom Deck (Dock):**
  - **Left:** ❤️ Wishlisted / Favorite items with instant re-add.
  - **Middle:** 🏠 Elevated Home Store icon with brand gradient and glow.
  - **Right:** 🛍️ Shopping Cart with real-time badge.
- **Floating Cart Deck:** Smoothly slides up whenever items are added, showing live item count, savings, and total bill.
- **Direct WhatsApp Orders:** One-tap order dispatch directly to the owner's WhatsApp (`7488151683`) with itemized billing, customer name, and delivery address.
- **Direct UPI Integration:** Displays store UPI (`7488151683@upi`) with 1-tap Google Pay / PhonePe / Paytm payment link (0% transaction fee).

### 🔐 Owner / Admin Management Portal
- **Discrete Top Switch:** Accessible from the top-right header.
- **Frosted Glass Security:** Demands Admin ID and Password with a smooth full-screen background blur (`BackdropFilter`).
- **Inventory Control:**
  - 1-tap instant switch between **In Stock** (Green) and **Out of Stock** (Red).
  - Add new products with custom pack sizes, MRP, and selling prices.
  - Edit or delete existing inventory items.
- **One-Click Standard Kirana Catalogue Loader:** Pre-populates the store with 50+ essential Indian grocery items across 9 departments (Atta, Rice, Pulses, Cooking Oils, Spices, Dairy, Biscuits, Cleaning, Personal Care).
- **Settings:** Update Admin ID and Owner Password securely with SHA-256 hashing.

---

## 🏗️ Architecture & Project Structure

```
shalimar_store/
├── assets/
│   ├── images/
│   │   └── logo.png              # High quality circular store logo
│   └── data/
│       └── standard_catalogue.json # 50+ pre-filled Kirana store items
├── lib/
│   ├── main.dart                 # App entry point & provider orchestration
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart    # Crimson Red (#B71C1C) & Warm Gold palette
│   │   │   └── app_constants.dart # Phone, UPI, & Storage keys
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Material 3 typography & styling
│   │   └── utils/
│   │       ├── currency_formatter.dart # ₹ INR formatting
│   │       └── whatsapp_helper.dart    # WhatsApp order dispatcher & UPI launcher
│   ├── models/
│   │   ├── product.dart           # Product model & discount calculation
│   │   ├── cart_item.dart         # Cart item with quantity & savings
│   │   ├── order_model.dart       # Order history & reorder tracking
│   │   └── user_profile.dart      # Customer profile & favorites
│   ├── providers/
│   │   ├── catalogue_provider.dart # Catalog state, search, category filter, CRUD
│   │   ├── cart_provider.dart      # Cart state, item counters, bill calculation
│   │   ├── user_provider.dart      # User profile, favorites, past orders
│   │   └── admin_provider.dart     # Authentication & admin mode state
│   ├── services/
│   │   ├── admin_auth_service.dart # SHA-256 hashed credentials verification
│   │   └── storage_service.dart    # Offline-first persistent storage
│   ├── views/
│   │   ├── onboarding/
│   │   │   └── welcome_onboarding_screen.dart # 4-slide tour & profile setup
│   │   ├── customer/
│   │   │   ├── customer_main_screen.dart      # Dock navigation & top bar
│   │   │   ├── profile_dialog.dart            # Profile, favorites & last orders
│   │   │   └── tabs/
│   │   │       ├── home_catalog_tab.dart      # Product grid & category pills
│   │   │       ├── favorites_tab.dart         # Saved wishlisted items
│   │   │       └── cart_tab.dart              # Cart summary, UPI ID, WhatsApp order
│   │   └── admin/
│   │       ├── admin_login_overlay.dart       # Frosted glass blur & sign in
│   │       ├── admin_dashboard_screen.dart    # Stock manager & KPI stats
│   │       ├── add_edit_product_dialog.dart   # Add/edit product modal
│   │       └── store_settings_dialog.dart     # Password & ID settings
│   └── widgets/
│       ├── bottom_deck_dock.dart              # Floating bottom dock
│       ├── floating_cart_bar.dart             # Animated slide-up cart pill
│       └── product_card.dart                  # Item card with +ADD counter
└── pubspec.yaml
```

---

## 📱 Releases & Installation

This application is built with **Split-per-ABI** configuration to minimize file size (only ~15–18 MB per architecture instead of a 60+ MB universal APK):

| Architecture | APK Target | Description |
| :--- | :--- | :--- |
| **arm64-v8a** | `app-arm64-v8a-release.apk` | Most modern Android smartphones (2018+) |
| **armeabi-v7a** | `app-armeabi-v7a-release.apk` | Older 32-bit Android devices |
| **x86_64** | `app-x86_64-release.apk` | Android emulators & Chromebooks |

### Installation Instructions
1. Download the `app-arm64-v8a-release.apk` (or matching architecture) from [GitHub Releases](https://github.com/nadeemalam178/shalimar-store/releases).
2. Open the downloaded file on your Android device and tap **Install**.
3. All permissions are verified clean (`INTERNET` for product images and `QUERIES` for WhatsApp / UPI).

---

## 🛡️ Default Admin Credentials

- **Admin ID:** `admin`
- **Owner Password:** `shalimar123`
*(Can be updated anytime inside the Admin Settings screen).*

---

## 👨‍💻 Developer & Store Information

- **Store:** Shalimar Store (Since 1988)
- **Helpline / WhatsApp:** +91 7488151683
- **Official UPI ID:** `7488151683@upi`
- **Developer:** [Nadeem Alam](https://github.com/nadeemalam178)
