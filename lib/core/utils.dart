import 'package:flutter/material.dart';

import 'constants.dart';

/// A readable error that the UI can show directly to the user.
class AppException implements Exception {
  final String message;

  /// True when the failure happened because there is no internet.
  final bool isNetworkError;

  const AppException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

/// Small helper functions used across the app.
class AppUtils {
  AppUtils._();

  static String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  /// Price before the discount was applied.
  static double originalPrice(double price, double discountPercentage) {
    if (discountPercentage <= 0 || discountPercentage >= 100) return price;
    return price / (1 - discountPercentage / 100);
  }

  /// Turns a slug like "home-decoration" into "Home Decoration".
  static String prettify(String slug) {
    if (slug.isEmpty) return slug;
    return slug
        .split('-')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > AppConstants.tabletBreakpoint;

  /// Columns for the product grid: 1 means a simple list (phones),
  /// tablets get 3 columns and wide screens 4.
  static int columnsForWidth(double width) {
    if (width <= AppConstants.tabletBreakpoint) return 1;
    if (width <= 900) return 3;
    return 4;
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : null,
        ),
      );
  }
}
