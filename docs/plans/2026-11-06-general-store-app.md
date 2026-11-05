# General Store App (Shalimar Store) Implementation Plan

> **For Agent:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a single, high-performance Flutter (Dart) mobile app for a general store ("Shalimar Store") with a customer-facing catalogue browser and an admin-only management portal protected by a simple ID & Password.

**Architecture:** A single Flutter application using layered clean architecture (Models, Services/Repositories, State Management via Provider/Riverpod, and UI Views). Data persistence supports both offline-first local storage (Hive/SQLite) and cloud database sync (Firebase Firestore) so admin updates reflect in real-time.

**Tech Stack:** 
- **Framework:** Flutter 3.47+ / Dart 3.13+
- **State Management:** `provider` (or `flutter_riverpod`)
- **Database:** `hive` & `hive_flutter` (for fast offline storage) / `cloud_firestore` (for multi-device sync)
- **Local Security / Auth:** `flutter_secure_storage` or hashed SharedPreferences for Admin ID & Password
- **Utilities:** `url_launcher` (direct WhatsApp order forwarding), `intl` (currency formatting in ₹ INR), `uuid`, `image_picker` (product photos)

---

## High-Level System Workflow

```mermaid
flowchart TD
    AppStart([App Launch]) --> ModeRouter{User Role}
    
    ModeRouter -->|Normal / Customer| CustomerCatalog[Customer Catalog View]
    CustomerCatalog --> SearchFilter[Search, Filter by Category]
    SearchFilter --> AddCart[Add Items to Cart]
    AddCart --> WhatsAppOrder[Send Order via WhatsApp to Store Owner]
    
    ModeRouter -->|Admin Icon Clicked| AdminGate[ID & Password Login Dialog]
    AdminGate --> CheckAuth{Credentials Valid?}
    CheckAuth -->|No| ShowError[Show Error / Shake Animation]
    ShowError --> CustomerCatalog
    CheckAuth -->|Yes| AdminDashboard[Admin Inventory & Catalogue Dashboard]
    
    AdminDashboard --> AddProduct[Add Single / Bulk Product]
    AdminDashboard --> EditProduct[Update Price, Unit, Stock Status]
    AdminDashboard --> DeleteProduct[Remove Product]
    AdminDashboard --> StoreSettings[Update Store Details & Admin Password]
    
    AddProduct --> Database[(Database: Local / Cloud Sync)]
    EditProduct --> Database
    DeleteProduct --> Database
    Database -.-> CustomerCatalog
```

---

## Database & Data Models

### 1. Product Model (`Product`)
- `id`: `String` (UUID)
- `name`: `String` (e.g., "Aashirvaad Shudh Chakki Atta")
- `category`: `String` (e.g., "Atta & Flours", "Dairy", "Spices", "Snacks")
- `price`: `double` (Selling Price in ₹)
- `mrp`: `double?` (Original MRP for showing discount)
- `unit`: `String` (e.g., "1 kg", "500 gm", "1 packet", "1 liter")
- `imageUrl`: `String?` (Network URL or local asset path)
- `inStock`: `bool` (Default: `true`)
- `description`: `String?`
- `createdAt`: `DateTime`

### 2. Category Model (`CategoryItem`)
- `id`: `String`
- `name`: `String`
- `iconName`: `String` (Material Icon representation)

### 3. Admin Credentials Structure
- `adminId`: Stored securely
- `passwordHash`: SHA-256 hashed password (Managed via secure configuration)
- `sessionActive`: In-memory session state with auto-lock on inactivity

---

## Detailed Step-by-Step Task Breakdown

### Phase 1: Project Initialization & Core Setup

#### Task 1: Initialize Flutter Project
**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`
- Step 1: Run `flutter create . --project-name shalimar_store --org com.shalimar.store`
- Step 2: Add essential dependencies in `pubspec.yaml`:
  - `provider: ^6.1.2`
  - `hive: ^2.2.3`
  - `hive_flutter: ^1.1.0`
  - `intl: ^0.19.0`
  - `uuid: ^4.5.1`
  - `url_launcher: ^6.3.1`
  - `shared_preferences: ^2.3.3`
  - `crypto: ^3.0.6`
- Step 3: Run `flutter pub get` and verify project compiles.

#### Task 2: Core Theme & App Constants
**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/constants/app_constants.dart`
- Design system: Warm emerald green / deep navy palette (classic grocery store aesthetic), ₹ INR currency helpers, typography rules.

---

### Phase 2: Data Layer & Services

#### Task 3: Product & Category Data Models
**Files:**
- Create: `lib/models/product.dart`
- Create: `lib/models/category_item.dart`
- Create: `lib/models/cart_item.dart`
- Test: Unit tests for JSON serialization and copyWith methods in `test/models/product_test.dart`.

#### Task 4: Admin Authentication Service
**Files:**
- Create: `lib/services/admin_auth_service.dart`
- Test: `test/services/admin_auth_service_test.dart`
- Features:
  - Default credentials initialized securely via SHA-256 hash.
  - Hashing using SHA-256 for secure comparison.
  - Persistent storage using `shared_preferences`.
  - Methods: `Future<bool> authenticate(String id, String password)`, `Future<bool> changePassword(String oldPass, String newPass)`, `bool get isLoggedIn`, `void logout()`.

#### Task 5: Catalogue Storage Service (Hive / SQLite Repository)
**Files:**
- Create: `lib/services/catalogue_service.dart`
- Features:
  - Local database CRUD: `getAllProducts()`, `addProduct(Product)`, `updateProduct(Product)`, `deleteProduct(String id)`.
  - Seeding initial sample catalog (Atta, Rice, Spices, Milk, Biscuits, Oil, Tea) so the store is not empty on first launch.
  - Bulk import capability: `Future<int> importProductsBatch(List<Product> items)`.

---

### Phase 3: Customer Facing UI (Catalog & Shopping List)

#### Task 6: State Management (CatalogueProvider & CartProvider)
**Files:**
- Create: `lib/providers/catalogue_provider.dart`
- Create: `lib/providers/cart_provider.dart`
- Logic: Search querying, category filtering, cart calculations (total items, total ₹ amount, discount savings).

#### Task 7: Customer Home Screen with Catalogue Browsing
**Files:**
- Create: `lib/views/customer/customer_home_screen.dart`
- Create: `lib/views/customer/widgets/product_card.dart`
- Create: `lib/views/customer/widgets/category_selector.dart`
- Create: `lib/views/customer/widgets/search_bar_widget.dart`
- UI elements:
  - Shalimar Store branded top bar with search bar and Admin lock icon button.
  - Horizontal scrolling category filter chips.
  - Grid/List view of items with price, unit, discount badge, and Add to Cart counter.
  - Floating Cart Summary bar showing `[X Items | ₹Total] -> View Cart`.

#### Task 8: Cart & WhatsApp Order Forwarding Screen
**Files:**
- Create: `lib/views/customer/cart_screen.dart`
- Features:
  - Detailed list of selected items with quantity increaser/decreaser.
  - Customer name and address entry (saved locally for convenience).
  - "Place Order on WhatsApp" button: Formats order items neatly (Item, Quantity, Price, Total Bill) and opens WhatsApp directly to Shalimar Store owner's phone number.

---

### Phase 4: Admin Portal (Protected by ID & Password)

#### Task 9: Simple Admin Login Dialog / Screen
**Files:**
- Create: `lib/views/admin/admin_login_dialog.dart`
- Features:
  - Clean modal dialog or dedicated screen triggered from the top-bar key icon.
  - Fields: `Admin ID` and `Password`.
  - Simple show/hide password toggle.
  - Validation: Authenticates against `AdminAuthService`.
  - Shake animation or red warning on incorrect credentials.

#### Task 10: Admin Dashboard & Inventory Management
**Files:**
- Create: `lib/views/admin/admin_dashboard_screen.dart`
- Features:
  - Inventory Overview: Total items count, low stock/out-of-stock items filter.
  - Quick Stock Toggle: 1-tap toggle to mark any item "In Stock" or "Out of Stock".
  - Floating Action Button: "Add New Item".
  - "Bulk Add Catalogue" button for rapid inventory loading.
  - Top Action: "Change Admin Password" and "Store Settings".

#### Task 11: Add / Edit Product Screen
**Files:**
- Create: `lib/views/admin/add_edit_product_screen.dart`
- Form fields:
  - Product Name (Required)
  - Category dropdown (Atta & Grains, Oil & Ghee, Masale/Spices, Snacks, Beverages, Dairy, Cleaning, etc.)
  - Selling Price (₹) & MRP (₹)
  - Unit / Pack size (e.g. 500g, 1kg, 200ml, 1 pc)
  - Image URL or predefined asset icon picker
  - Stock switch (Available / Sold Out)
- Save / Delete confirmation dialog.

#### Task 12: Bulk Catalogue Entry & Sample Data Loader
**Files:**
- Create: `lib/views/admin/bulk_catalogue_screen.dart`
- Features:
  - Quick multi-add table or Paste JSON/CSV format.
  - "Load Standard Indian Kirana Store Catalogue" button: Instantly loads 50+ pre-filled popular grocery items with standard Indian units & prices for immediate testing and use.

---

### Phase 5: Verification, Polish & Build

#### Task 13: End-to-End Verification
- Test 1: App launches in Customer Mode without requiring password.
- Test 2: Admin clicks login icon, enters wrong ID/password -> Access denied.
- Test 3: Admin enters correct ID/password -> Successfully unlocks Admin Panel.
- Test 4: Admin adds a new product -> Verify it appears instantly in the customer catalogue.
- Test 5: Admin toggles product to "Out of Stock" -> Customer card reflects "Out of Stock" and disables addition.
- Test 6: Customer adds 3 items to cart -> clicks WhatsApp Order -> WhatsApp opens with correctly formatted text message.

#### Task 14: Windows & Android Build Verification
- Run `flutter analyze`
- Run `flutter test`
- Build test executable or APK.

---

### Phase 6: Keyboard Ergonomics, Memory & Performance Optimization, Dynamic System Theme & Credential Rotation (v2.1.0 Plan)

#### 1. Admin Login Keyboard Ergonomics
- **Issue:** When tapping Admin ID or Password inputs, Android's on-screen keyboard covers the modal card, obscuring the password field and "Unlock Admin Panel" button.
- **Implementation Strategy:**
  - In `lib/views/admin/admin_login_overlay.dart`, observe `MediaQuery.of(context).viewInsets.bottom`.
  - Wrap the inner modal in a `SingleChildScrollView(physics: BouncingScrollPhysics())` wrapped by an `AnimatedPadding(padding: EdgeInsets.only(bottom: bottomInset))`.
  - Dynamically align the card from center to upper-center when `bottomInset > 0` so the inputs and submit button stay unobstructed above the keyboard.

#### 2. Memory Reduction & UI "Lightness" Optimization
- **Issue:** The app feels heavy on mid-tier/budget mobile phones due to unconstrained bitmap decoding and heavy GPU blur passes.
- **Implementation Strategy:**
  - **Memory Caching (`cacheWidth` / `cacheHeight`):**
    - Add `cacheWidth: 350`, `cacheHeight: 350` to `Image.network` and `ResizeImage(FileImage(file), width: 350)` in `ProductCard`, `CartTab`, `AdminDashboardScreen`, and dialogs.
    - Slashes in-memory bitmap footprint from ~24MB uncompressed down to ~350KB per thumbnail (85%+ RAM reduction).
  - **GPU Render Optimization:**
    - Replace heavy `BackdropFilter(sigma: 10)` passes with a lightweight `sigma: 4` blur combined with a tinted scrim (`Colors.black54`) to prevent GPU thermal throttling and frame drops.
  - **Render Virtualization & Repaint Boundaries:**
    - Add `RepaintBoundary` to each `ProductCard` to isolate repaint areas while fast scrolling through 1,000+ items.
  - **Add Items Photo Optimizer:**
    - In `AddEditProductDialog`, constrain `imageQuality: 80`, `maxWidth: 800`, `maxHeight: 800` on `ImagePicker` so captured camera/gallery photos do not blow up storage or RAM.

#### 3. Dynamic Android System Theme (Light / Dark Mode)
- **Requirement:** Dynamic adaptation to Android system theme without any manual UI toggle.
- **Implementation Strategy:**
  - Build `AppTheme.darkTheme` with an AMOLED dark palette:
    - Background: `#121212`, Surfaces/Cards: `#1E1E1E`, Brand Crimson: `#E53935`, Warm Gold: `#FFC107`, High-contrast text `#FFFFFF` / `#B0B0B0`.
  - Update `lib/main.dart` with:
    - `theme: AppTheme.lightTheme`
    - `darkTheme: AppTheme.darkTheme`
    - `themeMode: ThemeMode.system`
  - Update widgets (`CustomerMainScreen`, `HomeCatalogTab`, `CartTab`, `FavoritesTab`, `ProductCard`, `AdminDashboardScreen`) to use theme tokens (`Theme.of(context).colorScheme.surface`, `Theme.of(context).cardColor`) instead of hardcoded `Colors.white` / `Colors.black`.

#### 4. Credential Rotation
- **New Credentials:**
  - **Admin ID:** `Shalimar@1988`
  - **Owner Password:** `Shal1mar@1988#`
  - **SHA-256 Hash:** `e556e2eb347e2edd9af22f7298d0e19d66c6b21a6b416b46531fcdf2ae1c317b`
- **Implementation Strategy:**
  - Update `secure_credentials/OWNER_CREDENTIALS.txt`.
  - Update `lib/core/constants/app_constants.dart` (`defaultAdminId`, `defaultAdminPasswordHash`).
  - Update unit tests in `test/widget_test.dart` to verify the new credentials pass authentication.

#### 5. Expandable Product Detail View with Multi-Image Gallery & Recommendation Carousels
- **Requirement:** Tapping any product opens an expanded detail view showing multi-image gallery/swipe, comprehensive details, and two horizontal recommendation scroll rows:
  1. **"More Like This"** (products from the same category)
  2. **"More For You"** (popular cross-category essentials)
- **Implementation Strategy:**
  - **Data Model Extension:**
    - In `lib/models/product.dart`, add `List<String> images`. If `images` is empty, automatically defaults to `[imageUrl]` for 100% backward compatibility.
  - **Screen Implementation (`lib/views/customer/product_detail_screen.dart`):**
    - **Hero Animation:** Fluid transition expanding the card image from the grid to the top of the detail screen.
    - **Swipeable Image Carousel:** `PageView.builder` with dot indicators supporting multiple product photos (front, nutrition facts, back).
    - **Rich Information Card:** Brand title, unit tag, stock status badge, selling price vs MRP discount pill, and full item description.
    - **Sticky Bottom Action Bar:** Heart favorite toggle, item counter (`-` / `+`), and total price calculation with instant cart sync.
    - **Recommendation Section 1 — "More Like This":**
      - Horizontal scroll list displaying products sharing the same category (excluding current item).
    - **Recommendation Section 2 — "More For You":**
      - Horizontal scroll list displaying popular, high-rotation items from other categories (e.g. Oils, Dairy, Spices, Snacks).
    - **Instant Navigation:** Tapping any recommended item seamlessly navigates to that product's detail screen.

#### 6. Firebase Real-Time Cloud Sync & Push Notifications (3-Step Roadmap)
- **Goal:** Enable store owner to update catalog/stock on their phone and have every customer's phone update automatically with push notifications, while preserving offline-first functionality.
- **Step 1: Real-Time Cloud Database (Google Firebase Firestore — 100% Free Spark Tier)**
  - Add `firebase_core` and `cloud_firestore` to `pubspec.yaml`.
  - Maintain offline-first cache: Customer phones read instantly from local storage cache; when connected to internet, Firestore streams delta updates (<10 KB).
  - When the Owner marks an item out of stock or adds a product in Admin Panel, Firestore syncs to all online customer devices within <1 second with zero app updates.
- **Step 2: Dual-Tier Notification Engine (In-App Badges + FCM Push Notifications)**
  - **In-App Live Alerts:** Badge overlays on Cart and Wishlist items if an item goes out of stock or returns to stock.
  - **Phone Push Notifications (Firebase Cloud Messaging - FCM):**
    - `topic: store_broadcast`: Broadcasts new arrivals, seasonal festival discounts, and newly added categories to all store customers.
    - `topic: stock_{productId}`: Customers who favorited an out-of-stock product automatically subscribe to this topic; when the admin flips the stock switch to "In Stock", an automated push notification alerts them: *"🎉 Good news! [Product Name] is back in stock at Shalimar Store!"*
- **Step 3: Update Separation Matrix**
  - **Catalog & Stock Updates:** Synchronized silently via Cloud Firestore with zero downloads or app reinstalls.
  - **Software App Updates (APK):** Detected via the GitHub Releases OTA update banner built into the store header with 1-tap APK download.




