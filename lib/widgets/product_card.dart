import 'package:material_ui/material_ui.dart';

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
    final language = Localizations.localeOf(context).languageCode;
    // Decode grid thumbnails near their rendered physical size instead of
    // keeping the full-resolution upload in memory for every visible card.
    final imageDecodeSize =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context) /
                2)
            .round();
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
                          cacheWidth: imageDecodeSize,
                          cacheHeight: imageDecodeSize,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEDEDF4),
                            child: Icon(Icons.broken_image_outlined, size: 42),
                          ),
                        ),
                  if (onFavoriteTap != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: isFavorite ? Colors.red : Colors.white,
                            side: BorderSide.none,
                          ),
                          tooltip: isFavorite
                              ? strings.removeFavoriteTooltip
                              : strings.addFavoriteTooltip,
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.white,
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
          if (product.hasVariants) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: product.variants.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${v.color ?? ''}${v.color != null && v.size != null ? ' / ' : ''}${v.size ?? ''}', style: const TextStyle(fontSize: 10)),
              )).toList(),
            ),
            Text(
              product.availableQuantity == 0
                  ? (language == 'ar' ? 'نفد المخزون' : language == 'fr' ? 'Épuisé' : 'Out of stock')
                  : '${language == 'ar' ? 'المتاح' : language == 'fr' ? 'Disponible' : 'Available'}: ${product.availableQuantity}',
              style: TextStyle(fontSize: 11, color: product.availableQuantity == 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary),
            ),
          ],
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
