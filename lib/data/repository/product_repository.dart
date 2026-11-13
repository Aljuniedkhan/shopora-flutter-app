import '../../core/utils.dart';
import '../datasource/product_local_datasource.dart';
import '../datasource/product_remote_datasource.dart';
import '../model/product_model.dart';

enum SortOption { none, priceLowToHigh, priceHighToLow, rating }

/// Single place the providers ask for data.
///
/// It decides whether data comes from the API or from Hive, and merges
/// the user's local changes (added / edited / deleted products) on top
/// of the API data so they survive every refresh.
class ProductRepository {
  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;

  ProductRepository(this._remote, this._local);

  // ---------- Reading products ----------

  /// Loads one page from the API, caches it and applies local changes.
  Future<ProductPage> fetchProducts({
    required int skip,
    String query = '',
    String? category,
    SortOption sort = SortOption.none,
  }) async {
    final sortBy = _sortBy(sort);
    final order = _order(sort);

    final ProductPage page;
    if (query.isNotEmpty) {
      page = await _remote.searchProducts(
        query: query,
        skip: skip,
        sortBy: sortBy,
        order: order,
      );
    } else if (category != null) {
      page = await _remote.fetchByCategory(
        category: category,
        skip: skip,
        sortBy: sortBy,
        order: order,
      );
    } else {
      page = await _remote.fetchProducts(
        skip: skip,
        sortBy: sortBy,
        order: order,
      );
    }

    await _local.cacheProducts(page.products);

    final merged = _applyLocalChanges(page.products);
    // Locally added products are shown once, on top of the first page.
    if (skip == 0) {
      merged.insertAll(0, _addedProductsMatching(query, category));
    }
    return ProductPage(products: merged, total: page.total);
  }

  /// Offline version: every cached product, filtered on the device.
  List<Product> getCachedProducts({
    String query = '',
    String? category,
    SortOption sort = SortOption.none,
  }) {
    final cached = _local.getCachedProducts()
      ..sort((a, b) => a.id.compareTo(b.id));
    final merged = _applyLocalChanges(cached)
        .where((p) => _matches(p, query, category))
        .toList();
    merged.insertAll(0, _addedProductsMatching(query, category));
    return sortProducts(merged, sort);
  }

  /// Full details of one product. Falls back to the cache when offline.
  Future<Product> getProductDetail(int id) async {
    if (id < 0) {
      final added = _local.getAddedProduct(id);
      if (added == null) throw const AppException('Product not found.');
      return added;
    }

    final edited = _local.getEditedProduct(id);
    if (edited != null) return edited;

    try {
      final product = await _remote.fetchProductById(id);
      await _local.cacheProducts([product]);
      return product;
    } on AppException {
      final cached = _local.getCachedProduct(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Categories from the API, or the cached list when offline.
  Future<List<String>> getCategories() async {
    try {
      final categories = await _remote.fetchCategories();
      await _local.cacheCategories(categories);
      return categories;
    } on AppException {
      return _local.getCachedCategories();
    }
  }

  // ---------- CRUD ----------
  // DummyJSON does not really save changes, so after the API call
  // succeeds the result is stored in Hive to make it permanent.

  Future<Product> addProduct(Product product) async {
    final response = await _remote.addProduct(product);
    // Negative timestamp id = unique and never clashes with API ids.
    final saved = response.copyWith(
      id: -DateTime.now().millisecondsSinceEpoch,
      thumbnail: product.thumbnail,
    );
    await _local.saveAddedProduct(saved);
    return saved;
  }

  Future<Product> updateProduct(Product product) async {
    if (product.isLocal) {
      // Exists only on this device, so no API call is needed.
      await _local.saveAddedProduct(product);
    } else {
      await _remote.updateProduct(product);
      await _local.saveEditedProduct(product);
    }
    if (_local.isFavorite(product.id)) await _local.saveFavorite(product);
    return product;
  }

  Future<void> deleteProduct(Product product) async {
    if (product.isLocal) {
      await _local.removeAddedProduct(product.id);
    } else {
      await _remote.deleteProduct(product.id);
      await _local.markDeleted(product.id);
      await _local.removeEditedProduct(product.id);
    }
    await _local.removeFavorite(product.id);
  }

  // ---------- Favorites ----------

  List<Product> getFavorites() => _local.getFavorites();

  bool isFavorite(int id) => _local.isFavorite(id);

  /// Returns true if the product is now a favorite.
  Future<bool> toggleFavorite(Product product) async {
    if (_local.isFavorite(product.id)) {
      await _local.removeFavorite(product.id);
      return false;
    }
    await _local.saveFavorite(product);
    return true;
  }

  // ---------- Helpers ----------

  List<Product> sortProducts(List<Product> products, SortOption sort) {
    final sorted = List<Product>.from(products);
    switch (sort) {
      case SortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.none:
        break;
    }
    return sorted;
  }

  /// Removes deleted products and replaces edited ones.
  List<Product> _applyLocalChanges(List<Product> products) {
    final deletedIds = _local.getDeletedIds();
    final edited = _local.getEditedProducts();
    return products
        .where((p) => !deletedIds.contains(p.id))
        .map((p) => edited[p.id] ?? p)
        .toList();
  }

  List<Product> _addedProductsMatching(String query, String? category) {
    return _local
        .getAddedProducts()
        .where((p) => _matches(p, query, category))
        .toList();
  }

  bool _matches(Product product, String query, String? category) {
    if (category != null && product.category != category) return false;
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return product.title.toLowerCase().contains(q) ||
        product.description.toLowerCase().contains(q) ||
        product.brand.toLowerCase().contains(q) ||
        product.category.toLowerCase().contains(q);
  }

  String? _sortBy(SortOption sort) {
    switch (sort) {
      case SortOption.priceLowToHigh:
      case SortOption.priceHighToLow:
        return 'price';
      case SortOption.rating:
        return 'rating';
      case SortOption.none:
        return null;
    }
  }

  String? _order(SortOption sort) {
    switch (sort) {
      case SortOption.priceLowToHigh:
        return 'asc';
      case SortOption.priceHighToLow:
      case SortOption.rating:
        return 'desc';
      case SortOption.none:
        return null;
    }
  }
}
