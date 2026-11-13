import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/product_model.dart';
import '../../providers/product_provider.dart';
import 'product_card.dart';

/// Responsive product list used inside a CustomScrollView.
/// [columns] == 1 gives a list (phones), more gives a grid (tablets).
class ProductSliverGrid extends StatelessWidget {
  final List<Product> products;
  final int columns;
  final void Function(Product product) onProductTap;

  const ProductSliverGrid({
    super.key,
    required this.products,
    required this.columns,
    required this.onProductTap,
  });

  /// Height of one grid card; enough for image + text.
  static const double gridItemHeight = 320;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    Widget buildCard(BuildContext context, int index) {
      final product = products[index];
      return ProductCard(
        product: product,
        isGrid: columns > 1,
        isFavorite: provider.isFavorite(product.id),
        onTap: () => onProductTap(product),
        onFavoriteTap: () => provider.toggleFavorite(product),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      sliver: columns == 1
          ? SliverList.separated(
              itemCount: products.length,
              itemBuilder: buildCard,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            )
          : SliverGrid.builder(
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: gridItemHeight,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: buildCard,
            ),
    );
  }
}
