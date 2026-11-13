import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../model/product_model.dart';

/// Talks to the DummyJSON REST API using Dio.
class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
              sendTimeout: AppConstants.receiveTimeout,
              headers: {'Content-Type': 'application/json'},
            ),
          );

  /// GET /products?limit=10&skip=n
  Future<ProductPage> fetchProducts({
    required int skip,
    String? sortBy,
    String? order,
  }) {
    return _getPage('/products', skip: skip, sortBy: sortBy, order: order);
  }

  /// GET /products/search?q=query&limit=10&skip=n
  Future<ProductPage> searchProducts({
    required String query,
    required int skip,
    String? sortBy,
    String? order,
  }) {
    return _getPage(
      '/products/search',
      skip: skip,
      sortBy: sortBy,
      order: order,
      extra: {'q': query},
    );
  }

  /// GET /products/category/{slug}
  Future<ProductPage> fetchByCategory({
    required String category,
    required int skip,
    String? sortBy,
    String? order,
  }) {
    return _getPage(
      '/products/category/$category',
      skip: skip,
      sortBy: sortBy,
      order: order,
    );
  }

  /// GET /products/category-list
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dio.get('/products/category-list');
      return List<String>.from(response.data as List);
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// GET /products/{id}
  Future<Product> fetchProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// POST /products/add (DummyJSON only simulates it, nothing is saved).
  Future<Product> addProduct(Product product) async {
    try {
      final response = await _dio.post(
        '/products/add',
        data: product.toRequestBody(),
      );
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// PUT /products/{id} (simulated by DummyJSON).
  Future<void> updateProduct(Product product) async {
    try {
      await _dio.put('/products/${product.id}', data: product.toRequestBody());
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// DELETE /products/{id} (simulated by DummyJSON).
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// Shared code for every endpoint that returns a list of products.
  Future<ProductPage> _getPage(
    String path, {
    required int skip,
    String? sortBy,
    String? order,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {
          'limit': AppConstants.pageSize,
          'skip': skip,
          'sortBy': ?sortBy, // added only when not null
          'order': ?order,
          ...extra,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final products = (data['products'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      return ProductPage(
        products: products,
        total: (data['total'] as num?)?.toInt() ?? products.length,
      );
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// Converts a technical Dio error into a friendly message.
  AppException _toAppException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The server is taking too long to respond. Please try again.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return const AppException(
          'No internet connection. Please check your network.',
          isNetworkError: true,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) return const AppException('Product not found.');
        return AppException('Server error ($code). Please try again later.');
      default:
        return const AppException('Something went wrong. Please try again.');
    }
  }
}
