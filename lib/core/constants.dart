/// App-wide constant values kept in one place.
class AppConstants {
  AppConstants._();

  static const String appName = 'Shopora';
  static const String tagline = 'Discover products you love';

  // API
  static const String baseUrl = 'https://dummyjson.com';
  static const int pageSize = 10;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Hive box names
  static const String productsCacheBox = 'products_cache';
  static const String addedProductsBox = 'added_products';
  static const String editedProductsBox = 'edited_products';
  static const String deletedIdsBox = 'deleted_ids';
  static const String favoritesBox = 'favorites';
  static const String settingsBox = 'settings';

  // Keys inside the settings box
  static const String darkModeKey = 'is_dark_mode';
  static const String categoriesKey = 'categories';

  // UI
  static const double tabletBreakpoint = 600;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);
}
