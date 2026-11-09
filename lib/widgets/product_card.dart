import 'package:flutter/material.dart';

import '../models/product.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
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
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      color: Color(0xFF5558C9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
