import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../data/model/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/product_image.dart';
import 'add_edit_product_screen.dart';

/// Full information about one product.
class DetailScreen extends StatefulWidget {
  final Product product;

  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Product> _productFuture;
  int _currentImage = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Load the latest details; the list item is shown meanwhile.
    _productFuture = context.read<ProductProvider>().getProductDetail(
      widget.product.id,
    );
  }

  Future<void> _edit(Product product) async {
    final updated = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
    if (updated != null) {
      setState(() => _productFuture = Future.value(updated));
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Delete product?'),
        content: Text('"${product.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await context.read<ProductProvider>().deleteProduct(product);
      if (!mounted) return;
      AppUtils.showSnackBar(context, 'Product deleted');
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppUtils.showSnackBar(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder rebuilds when the Future finishes.
    // initialData shows the product from the list right away.
    return FutureBuilder<Product>(
      future: _productFuture,
      initialData: widget.product,
      builder: (context, snapshot) {
        final product = snapshot.data ?? widget.product;
        final isRefreshing =
            snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, product),
              if (isRefreshing)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    // Keeps text readable on wide tablet screens.
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _ProductInfo(product: product),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Uses the FutureBuilder's context so context.select works there.
  Widget _buildAppBar(BuildContext context, Product product) {
    final isFavorite = context.select<ProductProvider, bool>(
      (p) => p.isFavorite(product.id),
    );
    final images = product.galleryImages;
    final height = AppUtils.isTablet(context) ? 420.0 : 320.0;

    return SliverAppBar(
      pinned: true,
      expandedHeight: height,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Favorite',
          onPressed: () =>
              context.read<ProductProvider>().toggleFavorite(product),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : null,
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Edit',
          onPressed: _isDeleting ? null : () => _edit(product),
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton.filledTonal(
          tooltip: 'Delete',
          onPressed: _isDeleting ? null : () => _delete(product),
          icon: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image gallery: swipe left/right between pictures.
            PageView.builder(
              itemCount: images.isEmpty ? 1 : images.length,
              onPageChanged: (index) => setState(() => _currentImage = index),
              itemBuilder: (context, index) {
                final image = ProductImage(
                  url: images.isEmpty ? '' : images[index],
                  fit: BoxFit.contain,
                );
                // Only the first picture takes part in the Hero animation.
                if (index != 0) return image;
                return Hero(tag: 'product-image-${product.id}', child: image);
              },
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: _PageDots(count: images.length, current: _currentImage),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Everything below the image gallery.
class _ProductInfo extends StatelessWidget {
  final Product product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDiscount = product.discountPercentage > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppUtils.prettify(product.category).toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                AppUtils.formatPrice(product.price),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasDiscount) ...[
                Text(
                  AppUtils.formatPrice(
                    AppUtils.originalPrice(
                      product.price,
                      product.discountPercentage,
                    ),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Chip(
                  label: Text(
                    '-${product.discountPercentage.toStringAsFixed(0)}%',
                  ),
                  backgroundColor: colorScheme.errorContainer,
                  labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoTile(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                label: 'Rating',
                value: product.rating.toStringAsFixed(1),
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.inventory_2_rounded,
                iconColor: product.stock < 10 ? colorScheme.error : null,
                label: 'Stock',
                value: product.stock > 0 ? '${product.stock}' : 'Out',
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.sell_rounded,
                label: 'Brand',
                value: product.brand.isEmpty ? '-' : product.brand,
              ),
            ],
          ),
          const _SectionTitle('Description'),
          Text(product.description, style: theme.textTheme.bodyLarge),
          const _SectionTitle('Details'),
          _DetailRow(label: 'Brand', value: product.brand),
          _DetailRow(
            label: 'Category',
            value: AppUtils.prettify(product.category),
          ),
          _DetailRow(
            label: 'Discount',
            value: '${product.discountPercentage.toStringAsFixed(2)}%',
          ),
          if (product.tags.isNotEmpty) ...[
            const _SectionTitle('Tags'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in product.tags)
                  Chip(label: Text('#$tag'), side: BorderSide.none),
              ],
            ),
          ],
          _SectionTitle('Reviews (${product.reviews.length})'),
          if (product.reviews.isEmpty)
            Text(
              'No reviews yet.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            for (final review in product.reviews) _ReviewCard(review: review),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // API dates look like 2025-04-30T09:41:02.053Z; keep only the day.
    final date = review.date.length >= 10
        ? review.date.substring(0, 10)
        : review.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    review.reviewerName.isEmpty ? '?' : review.reviewerName[0],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(date, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}
