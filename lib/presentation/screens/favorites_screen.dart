import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../providers/product_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/product_grid.dart';
import 'detail_screen.dart';

/// Products the user marked with the heart icon (saved in Hive).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.favorites.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the heart on any product to save it here.',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  ProductSliverGrid(
                    products: provider.favorites,
                    columns: AppUtils.columnsForWidth(constraints.maxWidth),
                    onProductTap: (product) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(product: product),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
