import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopora/data/datasource/product_local_datasource.dart';
import 'package:shopora/data/datasource/product_remote_datasource.dart';
import 'package:shopora/data/model/product_model.dart';
import 'package:shopora/data/repository/product_repository.dart';
import 'package:shopora/presentation/screens/detail_screen.dart';
import 'package:shopora/presentation/screens/home_screen.dart';
import 'package:shopora/providers/product_provider.dart';
import 'package:shopora/providers/theme_provider.dart';
import 'package:shopora/services/connectivity_service.dart';

Product _product(int id) => Product(
  id: id,
  title: 'Product number $id with a fairly long title',
  description: 'Description of product $id. ' * 5,
  category: 'beauty',
  price: id * 3.5,
  discountPercentage: 12,
  rating: 4.3,
  stock: 5,
  brand: 'Brand $id',
  tags: const ['tag-one', 'tag-two'],
  reviews: const [
    Review(
      rating: 4,
      comment: 'Nice',
      reviewerName: 'Sam',
      date: '2025-04-30T09:41',
    ),
  ],
);

/// Fake API: 25 products, 10 per page, no real network.
class FakeRemote extends ProductRemoteDataSource {
  @override
  Future<ProductPage> fetchProducts({
    required int skip,
    String? sortBy,
    String? order,
  }) async {
    final all = List.generate(25, (i) => _product(i + 1));
    return ProductPage(products: all.skip(skip).take(10).toList(), total: 25);
  }

  @override
  Future<List<String>> fetchCategories() async => ['beauty', 'home-decoration'];

  @override
  Future<Product> fetchProductById(int id) async => _product(id);
}

class FakeConnectivity extends ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream.empty();
}

void main() {
  late ProductLocalDataSource local;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('shopora_test');
    local = ProductLocalDataSource();
    await local.init(testPath: dir.path);
  });

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = ProductProvider(
      ProductRepository(FakeRemote(), local),
      FakeConnectivity(),
    );
    await tester.runAsync(provider.init);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(local)),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
  }

  // Tablet runs first: the phone test ends with a Hive write that is
  // still queued inside the fake test clock.
  testWidgets('tablet: grid without overflow', (tester) async {
    await pumpHome(tester, const Size(1000, 800));
    expect(find.byType(GridView), findsNothing); // sliver grid is used
    expect(find.textContaining('Product number 1 '), findsOneWidget);
  });

  testWidgets('phone: list, infinite scroll and detail', (tester) async {
    await pumpHome(tester, const Size(400, 800));
    expect(find.textContaining('Product number 1 '), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);

    await tester.runAsync(
      () => tester
          .state<State>(find.byType(HomeScreen))
          .context
          .read<ProductProvider>()
          .loadMore(),
    );
    await tester.runAsync(
      () => tester
          .state<State>(find.byType(HomeScreen))
          .context
          .read<ProductProvider>()
          .loadMore(),
    );
    await tester.pump();
    final provider = tester
        .state<State>(find.byType(HomeScreen))
        .context
        .read<ProductProvider>();
    expect(provider.products.length, 25);
    expect(provider.hasMore, isFalse);

    await tester.tap(find.textContaining('Product number 1 '));
    // Let the detail Future (which writes to Hive) finish for real.
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Reviews (1)'), findsOneWidget);
  });
}
