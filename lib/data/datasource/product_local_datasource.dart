import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../model/product_model.dart';

/// Stores data on the device using Hive.
///
/// Products are saved as plain Maps (product.toJson()) so no Hive
/// adapters or code generation are needed. Keys are product ids as
/// Strings because Hive does not allow negative int keys.
class ProductLocalDataSource {
  late final Box _cacheBox; // products fetched from the API
  late final Box _addedBox; // products created in the app
  late final Box _editedBox; // API products edited in the app
  late final Box _deletedBox; // ids of API products deleted in the app
  late final Box _favoritesBox; // favorite products
  late final Box _settingsBox; // dark mode, cached categories

  /// Opens every box. Must be called once before the app starts.
  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(AppConstants.productsCacheBox);
    _addedBox = await Hive.openBox(AppConstants.addedProductsBox);
    _editedBox = await Hive.openBox(AppConstants.editedProductsBox);
    _deletedBox = await Hive.openBox(AppConstants.deletedIdsBox);
    _favoritesBox = await Hive.openBox(AppConstants.favoritesBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // ---------- API cache ----------

  Future<void> cacheProducts(List<Product> products) async {
    final entries = {for (final p in products) p.id.toString(): p.toJson()};
    await _cacheBox.putAll(entries);
  }

  List<Product> getCachedProducts() => _readAll(_cacheBox);

  Product? getCachedProduct(int id) => _read(_cacheBox, id);

  Future<void> cacheCategories(List<String> categories) =>
      _settingsBox.put(AppConstants.categoriesKey, categories);

  List<String> getCachedCategories() => List<String>.from(
      _settingsBox.get(AppConstants.categoriesKey, defaultValue: const []));

  // ---------- Local changes (added / edited / deleted) ----------

  List<Product> getAddedProducts() {
    final products = _readAll(_addedBox);
    // Newest first: local ids are -timestamp, so smaller id = newer.
    products.sort((a, b) => a.id.compareTo(b.id));
    return products;
  }

  Product? getAddedProduct(int id) => _read(_addedBox, id);

  Future<void> saveAddedProduct(Product product) =>
      _addedBox.put(product.id.toString(), product.toJson());

  Future<void> removeAddedProduct(int id) => _addedBox.delete(id.toString());

  Map<int, Product> getEditedProducts() {
    return {for (final p in _readAll(_editedBox)) p.id: p};
  }

  Product? getEditedProduct(int id) => _read(_editedBox, id);

  Future<void> saveEditedProduct(Product product) =>
      _editedBox.put(product.id.toString(), product.toJson());

  Future<void> removeEditedProduct(int id) => _editedBox.delete(id.toString());

  Set<int> getDeletedIds() =>
      _deletedBox.keys.map((key) => int.parse(key as String)).toSet();

  Future<void> markDeleted(int id) => _deletedBox.put(id.toString(), true);

  // ---------- Favorites ----------

  List<Product> getFavorites() => _readAll(_favoritesBox);

  bool isFavorite(int id) => _favoritesBox.containsKey(id.toString());

  Future<void> saveFavorite(Product product) =>
      _favoritesBox.put(product.id.toString(), product.toJson());

  Future<void> removeFavorite(int id) => _favoritesBox.delete(id.toString());

  // ---------- Settings ----------

  bool getDarkMode() =>
      _settingsBox.get(AppConstants.darkModeKey, defaultValue: false) as bool;

  Future<void> saveDarkMode(bool isDark) =>
      _settingsBox.put(AppConstants.darkModeKey, isDark);

  // ---------- Helpers ----------

  Product? _read(Box box, int id) {
    final raw = box.get(id.toString());
    if (raw == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  List<Product> _readAll(Box box) {
    return box.values
        .map((raw) => Product.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }
}
