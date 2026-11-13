import 'package:flutter/material.dart';

import '../models/product.dart';
import '../l10n/app_strings.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.primaryImage == null
                      ? const ColoredBox(
                          color: Color(0xFFEDEDF4),
                          child: Icon(Icons.image_outlined, size: 42),
                        )
                      : Image.network(
                          product.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEDEDF4),
                            child: Icon(Icons.broken_image_outlined, size: 42),
                          ),
                        ),
                  if (onFavoriteTap != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.96),
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: IconButton(
                          tooltip: isFavorite
                              ? strings.removeFavoriteTooltip
                              : strings.addFavoriteTooltip,
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.blueGrey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.price.toStringAsFixed(0)} ${strings.currency}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
