import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class SpecialMarket {
  const SpecialMarket({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;
}

const specialMarkets = <SpecialMarket>[
  SpecialMarket(
    title: 'ركن الوكالة',
    description: 'محلات الجملة والتصفية والمخازن التجارية، مثل وكالة البلح وما يشبهها.',
    icon: Icons.storefront_outlined,
    highlights: ['محلات الملابس والأحذية والشنط', 'المفروشات والأدوات المنزلية', 'تجار الجملة ونصف الجملة والتصفية'],
  ),
  SpecialMarket(
    title: 'تجار السوشيال',
    description: 'اكتشف متاجر أصحاب صفحات Facebook وInstagram داخل كنزة هب.',
    icon: Icons.shopping_bag_outlined,
    highlights: ['صفحات ومتاجر داخل كنزة هب', 'منتجات وروابط التواصل', 'عرض المنتج مرة واحدة في السوق والمتجر'],
  ),
  SpecialMarket(
    title: 'الأنتيكات والتحف',
    description: 'مساحة متخصصة للتحف والمقتنيات والقطع الكلاسيكية المميزة.',
    icon: Icons.watch_outlined,
    highlights: ['التحف والقطع الفنية', 'الساعات والديكورات الكلاسيكية', 'المقتنيات والعملات والطوابع'],
  ),
  SpecialMarket(
    title: 'الهاند ميد',
    description: 'منتجات ومشغولات يدوية من أصحاب المواهب والحرف والمشروعات الصغيرة.',
    icon: Icons.brush_outlined,
    highlights: ['الكروشيه والتطريز والإكسسوارات', 'الفخار والخشب والمشغولات', 'الهدايا والمنتجات حسب الطلب'],
  ),
];

class SpecialMarketsScreen extends StatelessWidget {
  const SpecialMarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأسواق الخاصة')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اكتشف أسواقًا متخصصة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'السوق العام يظل مكانك لكل المنتجات، والأسواق الخاصة تساعدك توصل بسهولة لنوع المنتجات أو التجار اللي بتدور عليهم.',
                    style: TextStyle(height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specialMarkets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final market = specialMarkets[index];
                return _SpecialMarketCard(
                  market: market,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _SpecialMarketPreviewScreen(market: market),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'كل الأسواق مفتوحة للبائع العادي والبائع المحترف.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialMarketCard extends StatelessWidget {
  const _SpecialMarketCard({required this.market, required this.onTap});

  final SpecialMarket market;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(market.icon, color: AppColors.primary, size: 27),
              ),
              const Spacer(),
              Text(
                market.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondary),
              ),
              const SizedBox(height: 6),
              Text(
                market.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('استكشف', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_back_rounded, size: 15, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialMarketPreviewScreen extends StatelessWidget {
  const _SpecialMarketPreviewScreen({required this.market});

  final SpecialMarket market;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(market.title)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(market.icon, color: AppColors.primary, size: 64),
            ),
            const SizedBox(height: 22),
            Text(
              market.title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(market.description, style: const TextStyle(height: 1.6, color: AppColors.textSecondary)),
            const SizedBox(height: 22),
            const Text('ماذا ستجد هنا؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...market.highlights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 19),
                    const SizedBox(width: 9),
                    Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'هذه معاينة لتصميم السوق. لم يتم ربط المنتجات أو بيانات المتاجر بعد، وسيتم ذلك بعد مراجعة الجداول الحالية واعتماد طريقة الإضافة.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
