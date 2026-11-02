import 'package:flutter/material.dart';

import 'product_detail_screen.dart';

/// Backward-compatible screen name that delegates to the current product page.
class ProductDetailsScreen extends StatelessWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return ProductDetailScreen(productId: productId);
  }
}
