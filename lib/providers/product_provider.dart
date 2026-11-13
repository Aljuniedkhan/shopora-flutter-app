import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/debouncer.dart';
import '../core/utils.dart';
import '../data/model/product_model.dart';
import '../data/repository/product_repository.dart';
import '../services/connectivity_service.dart';

/// Holds all product related state for the UI.
///
/// Screens read the getters and call the methods; whenever something
/// changes, notifyListeners() rebuilds the widgets that listen.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final ConnectivityService _connectivity;
  final Debouncer _searchDebouncer =
      Debouncer(delay: AppConstants.searchDebounce);
  StreamSubscription<bool>? _connectionSubscription;

  ProductProvider(this._repository, this._connectivity) {
    _favorites = _repository.getFavorites();
  }

  List<Product> _products = [];
  List<Product> _favorites = [];
  List<String> _categories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;
  String? _errorMessage;
  bool _isNetworkError = false;
  String? _loadMoreError;

  // Pagination: how many API products were already requested.
  int _skip = 0;
  // Increases on every new search/filter, so late answers of old
  // requests can be ignored.
  int _requestId = 0;

  String _searchQuery = '';
  String? _selectedCategory;
  SortOption _sortOption = SortOption.none;

  List<Product> get products => _products;
  List<Product> get favorites => _favorites;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  bool get isNetworkError => _isNetworkError;
  String? get loadMoreError => _loadMoreError;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  SortOption get sortOption => _sortOption;

  /// Called once when the app starts.
  Future<void> init() async {
    _connectionSubscription =
        _connectivity.onStatusChange.listen(_onConnectionChanged);
    await Future.wait([loadProducts(), loadCategories()]);
  }

  void _onConnectionChanged(bool isOnline) {
    if (isOnline && _isOffline) {
      // Internet is back: get fresh data automatically.
      loadProducts();
      if (_categories.isEmpty) loadCategories();
    } else if (!isOnline && !_isOffline) {
      _isOffline = true;
      notifyListeners();
    }
  }

  // ---------- Loading ----------

  /// Loads the first page again (used for start, refresh, search,
  /// filter and sort).
  Future<void> loadProducts() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _isNetworkError = false;
    _loadMoreError = null;
    notifyListeners();

    if (await _connectivity.isOnline()) {
      try {
        final page = await _repository.fetchProducts(
          skip: 0,
          query: _searchQuery,
          category: _selectedCategory,
          sort: _sortOption,
        );
        if (requestId != _requestId) return;
        _products = _repository.sortProducts(page.products, _sortOption);
        _skip = AppConstants.pageSize;
        _hasMore = _skip < page.total;
        _isOffline = false;
      } on AppException catch (e) {
        if (requestId != _requestId) return;
        if (e.isNetworkError) {
          _loadFromCache();
        } else {
          _products = [];
          _errorMessage = e.message;
        }
      }
    } else {
      _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadFromCache() {
    _products = _repository.getCachedProducts(
      query: _searchQuery,
      category: _selectedCategory,
      sort: _sortOption,
    );
    _isOffline = true;
    _hasMore = false;

    final isFiltering = _searchQuery.isNotEmpty || _selectedCategory != null;
    if (_products.isEmpty && !isFiltering) {
      _errorMessage = 'You are offline and no saved data is available yet.';
      _isNetworkError = true;
    }
  }

  /// Infinite scroll: loads the next page when the user reaches the end.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _isOffline) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _repository.fetchProducts(
        skip: _skip,
        query: _searchQuery,
        category: _selectedCategory,
        sort: _sortOption,
      );
      if (requestId != _requestId) return;
      _products = _repository.sortProducts(
        [..._products, ...page.products],
        _sortOption,
      );
      _skip += AppConstants.pageSize;
      _hasMore = _skip < page.total;
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      _loadMoreError = e.message;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _repository.getCategories();
    notifyListeners();
  }

  Future<void> retry() async {
    await loadProducts();
    if (_categories.isEmpty) await loadCategories();
  }

  // ---------- Search, filter, sort ----------

  /// Called on every key press; the search runs 500ms after typing stops.
  void onSearchChanged(String text) {
    _searchDebouncer.run(() {
      final query = text.trim();
      if (query == _searchQuery) return;
      _searchQuery = query;
      _selectedCategory = null; // search always looks in every category
      loadProducts();
    });
  }

  void selectCategory(String? category) {
    if (category == _selectedCategory && _searchQuery.isEmpty) return;
    _selectedCategory = category;
    _searchQuery = '';
    loadProducts();
  }

  void changeSort(SortOption option) {
    if (option == _sortOption) return;
    _sortOption = option;
    loadProducts();
  }

  // ---------- Detail & CRUD ----------
  // These methods throw AppException; the screen shows it in a SnackBar.

  Future<Product> getProductDetail(int id) =>
      _repository.getProductDetail(id);

  Future<void> addProduct(Product product) async {
    final saved = await _repository.addProduct(product);
    final fitsCurrentList = _searchQuery.isEmpty &&
        (_selectedCategory == null || _selectedCategory == saved.category);
    if (fitsCurrentList) {
      _products = _repository.sortProducts([saved, ..._products], _sortOption);
    }
    notifyListeners();
  }

  Future<Product> updateProduct(Product product) async {
    final updated = await _repository.updateProduct(product);
    _products = [
      for (final p in _products) p.id == updated.id ? updated : p,
    ];
    _favorites = _repository.getFavorites();
    notifyListeners();
    return updated;
  }

  Future<void> deleteProduct(Product product) async {
    await _repository.deleteProduct(product);
    _products = _products.where((p) => p.id != product.id).toList();
    _favorites = _repository.getFavorites();
    notifyListeners();
  }

  // ---------- Favorites ----------

  bool isFavorite(int id) => _favorites.any((p) => p.id == id);

  Future<void> toggleFavorite(Product product) async {
    await _repository.toggleFavorite(product);
    _favorites = _repository.getFavorites();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _searchDebouncer.dispose();
    super.dispose();
  }
}
