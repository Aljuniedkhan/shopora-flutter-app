import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with disk caching, a placeholder and an error icon.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallback = Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    if (url.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) =>
          Container(color: colorScheme.surfaceContainerHighest),
      errorWidget: (context, url, error) => fallback,
    );
  }
}
