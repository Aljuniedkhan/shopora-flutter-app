import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../data/model/product_model.dart';
import 'product_image.dart';

/// Shows one product. [isGrid] switches between the phone list layout
/// (image on the left) and the tablet grid layout (image on top).
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isGrid;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: isGrid ? _buildGrid(context) : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 110, height: 110, child: _image()),
          ),
          const SizedBox(width: 12),
          Expanded(child: _details(context)),
          _favoriteButton(context),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            SizedBox(height: 160, width: double.infinity, child: _image()),
            Positioned(top: 4, right: 4, child: _favoriteButton(context)),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _details(context),
          ),
        ),
      ],
    );
  }

  Widget _image() {
    // The same tag is used on the detail screen for the Hero animation.
    return Hero(
      tag: 'product-image-${product.id}',
      child: ProductImage(url: product.mainImage),
    );
  }

  Widget _details(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                AppUtils.prettify(product.subtitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            if (product.isLocal) ...[
              const SizedBox(width: 6),
              const _LocalBadge(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          product.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (isGrid) const Spacer() else const SizedBox(height: 8),
        Row(
          children: [
            Text(
              AppUtils.formatPrice(product.price),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              product.rating.toStringAsFixed(1),
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _favoriteButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      visualDensity: VisualDensity.compact,
      style: isGrid
          ? IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withValues(alpha: 0.85),
            )
          : null,
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: onFavoriteTap,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Small label for products that were created on this device.
class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'My item',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colorScheme.onTertiaryContainer),
      ),
    );
  }
}
