class AppConstants {
  static const String appName = 'Shalimar Store';
  static const String appVersion = 'v3.0.0';
  static const String appTagline = 'Since 1988 • Quality & Trust';
  static const String ownerPhone = '7488151683';
  static const String ownerWhatsApp = '917488151683';
  static const String ownerUpiId = '7488151683@upi';

  // Secure Defaults: Default ID and Cryptographic SHA-256 Hash of Owner Password
  // Plain credentials are stored exclusively in secure_credentials/OWNER_CREDENTIALS.txt
  static const String defaultAdminId = 'Shalimar@1988';
  static const String defaultAdminPasswordHash =
      'e556e2eb347e2edd9af22f7298d0e19d66c6b21a6b416b46531fcdf2ae1c317b';

  static const String logoPath = 'assets/images/logo.png';
  static const String storeFrontImagePath = 'assets/images/store_front.jpg';
  static const String catalogueAssetPath = 'assets/data/standard_catalogue.json';

  // Store Real Details & Heritage Location (Patna, Bihar)
  static const String storeFullName = 'Md. Jamil General Store (Shalimar Store)';
  static const String storeAddress = 'Alam Ganj, Ashok Raj Path, Patna - 800007, Bihar';
  static const String storeLandmark = 'Ashok Rajpath, Alamganj Chowki / Thana Area';
  static const String storeHours = 'Open Daily: 7:00 AM – 10:30 PM';

  // Storage Keys
  static const String keyUsername = 'user_username';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyCart = 'stored_cart_items';
  static const String keyCustomCategories = 'stored_custom_categories';
  static const String keyProducts = 'stored_products';
  static const String keyFavorites = 'stored_favorites';
  static const String keyPastOrders = 'stored_past_orders';
  static const String keyAdminPasswordHash = 'admin_password_hash';
  static const String keyAdminId = 'admin_id';
  static const String keyStorePhone = 'store_phone';
  static const String keyStoreUpi = 'store_upi';
}
