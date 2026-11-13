import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../data/model/product_model.dart';
import '../../data/repository/product_repository.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/offline_banner.dart';
import '../widgets/product_grid.dart';
import 'add_edit_product_screen.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Infinite scroll: load the next page a little before the end.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMore();
    }
  }

  /// On big screens the first page may not fill the screen, so no
  /// scrolling can happen. In that case load more right away.
  void _fillScreenIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        context.read<ProductProvider>().loadMore();
      }
    });
  }

  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(product: product)),
    );
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
  }

  void _onCategorySelected(String? category) {
    _searchController.clear();
    context.read<ProductProvider>().selectCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              if (provider.isOffline) const OfflineBanner(),
              _CategoryBar(
                categories: provider.categories,
                selected: provider.selectedCategory,
                onSelected: _onCategorySelected,
              ),
              // Thin progress bar when reloading while old data is visible.
              if (provider.isLoading && provider.products.isNotEmpty)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final favoriteCount =
        context.select<ProductProvider, int>((p) => p.favorites.length);
    final themeProvider = context.watch<ThemeProvider>();
    final sortOption =
        context.select<ProductProvider, SortOption>((p) => p.sortOption);

    return AppBar(
      title: const Text(
        AppConstants.appName,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Favorites',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
          icon: Badge(
            isLabelVisible: favoriteCount > 0,
            label: Text('$favoriteCount'),
            child: const Icon(Icons.favorite_border_rounded),
          ),
        ),
        PopupMenuButton<SortOption>(
          tooltip: 'Sort',
          icon: const Icon(Icons.sort_rounded),
          initialValue: sortOption,
          onSelected: (option) =>
              context.read<ProductProvider>().changeSort(option),
          itemBuilder: (_) => const [
            PopupMenuItem(value: SortOption.none, child: Text('Default')),
            PopupMenuItem(
              value: SortOption.priceLowToHigh,
              child: Text('Price: Low to High'),
            ),
            PopupMenuItem(
              value: SortOption.priceHighToLow,
              child: Text('Price: High to Low'),
            ),
            PopupMenuItem(value: SortOption.rating, child: Text('Top Rated')),
          ],
        ),
        IconButton(
          tooltip: themeProvider.isDarkMode ? 'Light mode' : 'Dark mode',
          onPressed: themeProvider.toggleTheme,
          icon: Icon(themeProvider.isDarkMode
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          // Rebuilds only the field, so the clear button appears/hides.
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) => TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: context.read<ProductProvider>().onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProductProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppUtils.columnsForWidth(constraints.maxWidth);

        if (provider.isLoading && provider.products.isEmpty) {
          return LoadingShimmer(columns: columns);
        }

        if (provider.errorMessage != null && provider.products.isEmpty) {
          return provider.isNetworkError
              ? ErrorView.noInternet(onRetry: provider.retry)
              : ErrorView(
                  message: provider.errorMessage!,
                  onRetry: provider.retry,
                );
        }

        if (provider.hasMore && !provider.isLoadingMore) _fillScreenIfNeeded();

        return RefreshIndicator(
          onRefresh: provider.loadProducts,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (provider.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyView(provider),
                )
              else ...[
                ProductSliverGrid(
                  products: provider.products,
                  columns: columns,
                  onProductTap: _openDetail,
                ),
                SliverToBoxAdapter(child: _ListFooter(provider: provider)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(ProductProvider provider) {
    if (provider.searchQuery.isNotEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No results',
        message: 'Nothing matches "${provider.searchQuery}". '
            'Try another word.',
      );
    }
    return EmptyView(
      title: 'No products found',
      message: 'There is nothing to show here right now.',
      actionLabel: 'Refresh',
      onAction: provider.loadProducts,
    );
  }
}

/// Horizontal list of category chips. "All" removes the filter.
class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1];
          return ChoiceChip(
            label: Text(category == null ? 'All' : AppUtils.prettify(category)),
            selected: category == selected,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

/// Bottom of the list: loader, retry button or "No more products".
class _ListFooter extends StatelessWidget {
  final ProductProvider provider;

  const _ListFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;

    if (provider.isLoadingMore) {
      child = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (provider.loadMoreError != null) {
      child = TextButton.icon(
        onPressed: provider.retryLoadMore,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Could not load more. Retry'),
      );
    } else if (!provider.hasMore) {
      child = Text(
        'No more products',
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    } else {
      child = const SizedBox.shrink();
    }

    // Extra bottom space so the FAB never hides the last item.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Center(child: child),
    );
  }
}
