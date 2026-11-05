# Phase 4: AMOLED Dark Theme Overhaul, Production Hardening, In-App OTA Updates, Cloud Sync & Notifications Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Shalimar Store into a polished, production-grade retail platform by:
1. Completely overhauling the broken Dark Theme into a flawless, high-contrast AMOLED dark mode across every screen and widget.
2. Removing all test/demo pre-filled "Quick-Loader" options from the Admin Panel (production hardening).
3. Enabling direct in-app OTA APK downloads and native package installation without opening Chrome or external browsers.
4. Introducing real-time cloud catalog sync (Firebase Firestore) from the store owner's phone to all customer devices.
5. Implementing automated push notifications for stock restocks and store broadcasts.
6. Providing customer order history with receipts and camera barcode scanning.

**Architecture:**
- **Semantic Theme Engine:** Eliminates hardcoded `Colors.white`, `AppColors.background`, and `AppColors.darkText`. Replaces them with semantic theme accessors (`Theme.of(context).colorScheme.surface`, `Theme.of(context).scaffoldBackgroundColor`, `Theme.of(context).textTheme`) with custom helper extensions (`context.isDark`, `context.surfaceColor`, `context.textPrimaryColor`).
- **Production Cleanliness:** Strips demo/test loaders and reset triggers from the owner management panel.
- **In-App Direct OTA Pipeline:** HTTP chunk streaming in `UpdateService` with live progress modal (`InAppUpdateDialog`) and automatic Android package installer invocation via `open_filex`.
- **Hybrid Cloud Data:** `CatalogRepository` arbitrating between local offline cache (0ms cold start) and Firebase Firestore (`/products`, `/categories`) delta streams.
- **Push Notifications:** Firebase Cloud Messaging (FCM) + `flutter_local_notifications` with `restock_<productId>` topic pub/sub.

**Tech Stack:**
- Flutter 3.47+ / Dart 3.13+
- `open_filex: ^4.6.0` & `path_provider: ^2.1.5`
- `firebase_core: ^3.12.0` & `cloud_firestore: ^5.6.5`
- `firebase_messaging: ^15.2.4` & `flutter_local_notifications: ^18.0.1`
- `mobile_scanner: ^6.0.4`
- Google Fonts (`Plus Jakarta Sans`), Material 3

---

## Detailed Task Breakdown

### Task 1: Complete AMOLED Dark Theme Overhaul & Semantic Theme Tokens
Fix the broken dark theme implementation where hardcoded `Colors.white`, `AppColors.background`, and `AppColors.darkText` caused blinding white appbars, white search bars, white docks, and unreadable black text on dark cards.

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (Add semantic text and color definitions for light & AMOLED dark)
- Create: `lib/core/theme/theme_extensions.dart` (Add `BuildContext` extension for `isDark`, `cardColor`, `textPrimary`, `textSecondary`, `borderSubtle`, `inputFill`)
- Modify: `lib/views/customer/customer_main_screen.dart` (Remove hardcoded `Colors.white` AppBar & `AppColors.background`; use adaptive surface & border colors)
- Modify: `lib/views/customer/tabs/home_catalog_tab.dart` (Fix white pinned search bar, white category chips, and dark text headings)
- Modify: `lib/widgets/bottom_deck_dock.dart` (Fix hardcoded white container; adopt AMOLED dark `#1E1E1E` surface with emerald/gold active glow)
- Modify: `lib/widgets/floating_cart_bar.dart` (Adaptive contrast background and text)
- Modify: `lib/views/customer/tabs/cart_tab.dart` (Fix hardcoded white item cards, white empty state, white order summary, and text colors)
- Modify: `lib/views/customer/tabs/favorites_tab.dart` (Fix hardcoded background and heading text colors)
- Modify: `lib/views/customer/dialogs/store_heritage_dialog.dart` (Fix hardcoded white dialog background)
- Modify: `lib/views/customer/profile_dialog.dart` (Fix hardcoded white dialog background)
- Modify: `lib/views/admin/admin_dashboard_screen.dart` (Fix hardcoded white cards, filter buttons, and table rows)
- Create: `test/theme_consistency_test.dart`

**Step 1: Create Theme Extension Helper**
In `lib/core/theme/theme_extensions.dart`:
```dart
import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get scaffoldBg => isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get borderSubtle => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0);
  Color get inputFill => isDark ? const Color(0xFF262626) : Colors.white;
}
```

**Step 2: Write Theme Consistency Unit Test**
Verify that both `lightTheme` and `darkTheme` export valid `scaffoldBackgroundColor`, `cardColor`, and readable high-contrast text palettes.

**Step 3: Refactor CustomerMainScreen & HomeCatalogTab**
- Replace `AppBar(backgroundColor: Colors.white)` with `Theme.of(context).appBarTheme.backgroundColor`.
- Replace pinned search bar `Container(color: Colors.white)` with `Container(color: context.scaffoldBg)`.
- Replace search box decoration border with `context.borderSubtle` and input fill with `context.inputFill`.
- In category horizontal list:
  - If unselected: `color: context.surfaceColor`, `border: Border.all(color: context.borderSubtle)`, text color: `context.textSecondary`.
- Section titles: use `context.textPrimary`.

**Step 4: Refactor BottomDeckDock & FloatingCartBar**
- In `BottomDeckDock`: replace `color: Colors.white` with `context.surfaceColor`, border with `context.borderSubtle`.
- In `FloatingCartBar`: ensure dark mode has high-contrast emerald surface with pure white text and gold total tag.

**Step 5: Refactor CartTab & FavoritesTab**
- Replace `backgroundColor: AppColors.background` with `context.scaffoldBg`.
- Cart item cards: replace `color: Colors.white` with `context.surfaceColor`, border with `context.borderSubtle`.
- Item title: replace `AppColors.darkText` with `context.textPrimary`.
- Quantity counter pill: replace `color: Colors.grey.shade100` with `isDark ? Color(0xFF2A2A2A) : Colors.grey.shade100`.

**Step 6: Refactor Admin Dashboard & Heritage Dialogs**
- Update all dialogs and admin panels to use `context.surfaceColor` and `context.textPrimary`.

**Step 7: Verify with Tests & Commit**
Run: `flutter test`
```bash
git add lib/core/theme/ lib/views/ lib/widgets/ test/
git commit -m "fix(theme): complete AMOLED dark mode overhaul with semantic theme extensions"
```

---

### Task 2: Remove Pre-Filled Quick-Loader from Admin Panel (Production Hardening)
Remove the test/demo "Full Catalogue Quick-Loader" banner from the admin dashboard so only real store products are managed.

**Files:**
- Modify: `lib/views/admin/admin_dashboard_screen.dart:236-299` (Remove `Full Catalogue Quick-Loader` container, dialog, and buttons)
- Test: `test/admin_screen_test.dart`

**Step 1: Remove Quick-Loader UI Block**
Delete lines 236-299 from `admin_dashboard_screen.dart`. Keep only real store management controls:
- Real-time stock search and category filters
- Out-of-Stock breakdown card with 1-tap restock
- Category management drawer
- Add Product FAB and item table

**Step 2: Run tests and verify clean compilation**
Run: `flutter test`

**Step 3: Commit**
```bash
git add lib/views/admin/admin_dashboard_screen.dart
git commit -m "chore(admin): remove pre-filled quick-loader banner for production store deployment"
```

---

### Task 3: In-App Direct OTA APK Downloader & Native Package Installer
Ensure that tapping "Update Now" on the in-app update banner downloads the APK **directly inside the app** with a live progress dialog and automatically launches the native Android installer without opening Chrome or an external browser.

**Files:**
- Modify: `pubspec.yaml` (Add `open_filex: ^4.6.0`, `path_provider: ^2.1.5`)
- Modify: `android/app/src/main/AndroidManifest.xml` (Add `REQUEST_INSTALL_PACKAGES` permission)
- Modify: `lib/services/update_service.dart` (Add `downloadApkWithProgress` streaming chunk downloader)
- Create: `lib/views/customer/dialogs/in_app_update_dialog.dart`
- Modify: `lib/views/customer/tabs/home_catalog_tab.dart` (Open `InAppUpdateDialog` instead of external URL)
- Create: `test/update_service_test.dart`

**Step 1: Add dependencies & update AndroidManifest**
```yaml
dependencies:
  path_provider: ^2.1.5
  open_filex: ^4.6.0
```
In `AndroidManifest.xml`: `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`

**Step 2: Implement streaming chunk download in `UpdateService`**
Track received bytes vs total bytes, write to temporary app cache file `shalimar_store_update.apk`.

**Step 3: Create `InAppUpdateDialog`**
- Show progress percentage, downloaded MB vs total MB, and animated `LinearProgressIndicator`.
- On completion: invoke `OpenFilex.open(filePath, type: 'application/vnd.android.package-archive')` to launch native Android package installer.

**Step 4: Commit**
```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml lib/services/update_service.dart lib/views/customer/dialogs/in_app_update_dialog.dart lib/views/customer/tabs/home_catalog_tab.dart
git commit -m "feat(ota): add in-app APK downloader with progress dialog and native direct package installation"
```

---

### Task 4: Offline-First Repository Abstraction Layer
Decouple `CatalogProvider` from direct `SharedPreferences` reading to a dedicated `CatalogRepository` that arbitrates between local cached storage and remote cloud data.

**Files:**
- Create: `lib/repositories/catalog_repository.dart`
- Create: `test/catalog_repository_test.dart`
- Modify: `lib/providers/catalog_provider.dart`

**Step 1: Implement `CatalogRepository` with local cache fallback and dirty bit tracking**
**Step 2: Commit**
```bash
git add lib/repositories/catalog_repository.dart test/catalog_repository_test.dart
git commit -m "feat(repo): add CatalogRepository for unified local and cloud catalog access"
```

---

### Task 5: Firebase Firestore Real-Time Catalog Sync Bridge
Connect Firebase Firestore so when the store owner edits/adds products in the Admin Panel from their phone, it pushes changes to Cloud Firestore, which instantly updates all customer devices online without requiring app re-downloads.

**Files:**
- Modify: `pubspec.yaml` (Add `firebase_core`, `cloud_firestore`)
- Create: `lib/services/cloud_sync_service.dart`
- Create: `lib/services/firebase_config.dart`
- Modify: `lib/repositories/catalog_repository.dart`
- Modify: `lib/main.dart`

**Step 1: Add dependencies & implement CloudSyncService**
**Step 2: Commit**
```bash
git add pubspec.yaml pubspec.lock lib/services/cloud_sync_service.dart lib/services/firebase_config.dart
git commit -m "feat(cloud): add CloudSyncService for real-time Firestore catalog synchronization"
```

---

### Task 6: Dual-Tier Push Notification Engine (FCM + Local Notifications)
Implement real-time customer alerts for restocked items and new arrivals.

**Files:**
- Modify: `pubspec.yaml` (Add `firebase_messaging`, `flutter_local_notifications`)
- Create: `lib/services/notification_service.dart`
- Create: `lib/views/customer/notifications_screen.dart`
- Modify: `lib/views/customer/product_detail_screen.dart` (Add "Notify Me when Back in Stock" button)
- Modify: `lib/views/customer/customer_main_screen.dart` (Add notification bell icon with unread badge)

**Step 1: Implement NotificationService and dynamic `restock_<productId>` topic subscription**
**Step 2: Commit**
```bash
git add lib/services/notification_service.dart lib/views/customer/notifications_screen.dart lib/views/customer/product_detail_screen.dart
git commit -m "feat(notifications): add FCM push notifications and restock alert subscriptions"
```

---

### Task 7: Customer Order History & In-App WhatsApp Receipts
Allow customers to view their past orders, reorder items with 1 tap, and download/share clean formatted receipts.

**Files:**
- Create: `lib/models/order_record.dart`
- Create: `lib/services/order_history_service.dart`
- Create: `lib/views/customer/order_history_screen.dart`
- Create: `lib/views/customer/order_detail_screen.dart`
- Modify: `lib/views/customer/tabs/cart_tab.dart`

**Step 1: Implement order history ledger and 1-tap reorder flow**
**Step 2: Commit**
```bash
git add lib/models/order_record.dart lib/services/order_history_service.dart lib/views/customer/order_history_screen.dart
git commit -m "feat(orders): add customer order history tracking and instant re-order flow"
```

---

### Task 8: Hardware Barcode & QR Code Scanner for Admin Intake
Integrate device camera barcode scanning (`mobile_scanner`) to allow the store owner to scan packaged grocery barcodes (EAN-13, UPC) for 1-second stock lookup and instant product addition.

**Files:**
- Modify: `pubspec.yaml` (Add `mobile_scanner: ^6.0.4`)
- Create: `lib/views/admin/barcode_scanner_modal.dart`
- Modify: `lib/views/admin/add_edit_product_dialog.dart`
- Modify: `lib/views/admin/admin_dashboard_screen.dart`

**Step 1: Implement camera barcode viewfinder with laser guide and automatic lookup**
**Step 2: Commit**
```bash
git add lib/views/admin/barcode_scanner_modal.dart lib/views/admin/add_edit_product_dialog.dart
git commit -m "feat(scanner): add live camera barcode scanner for instant admin inventory intake"
```

---

### Task 9: Comprehensive Regression Verification & Release Packaging
Verify all tests pass, build signed split APKs, and publish release to GitHub.

**Files:**
- Run complete test suite: `flutter test`
- Run code analyzer: `flutter analyze --no-fatal-infos`
- Build release split APKs:
  `$env:ANDROID_HOME="C:\Users\Nadeem\AppData\Local\Android\Sdk"; flutter build apk --split-per-abi --release`
- Verify APK signatures via `apksigner`
- Tag and publish release to GitHub
