import 'package:flutter/material.dart';

class AboutKenzaScreen extends StatelessWidget {
  const AboutKenzaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن كنزة هب')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
                SizedBox(height: 18),
                Text('كنزة هب', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('لو مش محتاجها... غيرك محتاجها', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                Text('مساحة واحدة للتصفح والبيع واكتشاف المنتجات التي قد يحتاجها شخص آخر.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.7)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section('فكرة كنزة هب', 'نؤمن أن الشيء الذي لم تعد تحتاجه قد يكون مفيدًا لشخص آخر. لذلك نجمع البائعين والمشترين في سوق واحد بسيط وسهل الاستخدام.'),
          _section('ماذا تجد هنا؟', 'تصفح المنتجات واكتشف الملابس والأحذية ومستلزمات الأطفال والمنزل، وتواصل مع أصحاب المنتجات لمعرفة التفاصيل.'),
          _section('كيف تعمل المنصة؟', 'يمكنك التصفح كزائر. وعندما ترغب في إضافة منتج أو إدارة منتجاتك، أنشئ حسابًا أو سجّل الدخول.'),
          _section('هدفنا', 'تسهيل إعادة تداول المنتجات وإتاحة تجربة واضحة ومريحة للمجتمع.'),
          const SizedBox(height: 16),
          const Center(child: Text('© Kenza Hub', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(height: 1.8, color: Color(0xFF475569))),
    ]),
  );
}
