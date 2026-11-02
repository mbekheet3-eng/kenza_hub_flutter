import 'package:flutter/material.dart';

class AboutKenzaScreen extends StatelessWidget {
  const AboutKenzaScreen({super.key});

  static const Color _red = Color(0xFFC62828);
  static const Color _navy = Color(0xFF0F172A);

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
              color: _navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
                SizedBox(height: 18),
                Text(
                  'كنزة هب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'لو مش محتاجها... غيرك محتاجها',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'بيع واشتري بسهولة من غير عمولة',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section(
            context,
            title: 'فكرتنا',
            body:
                'كنزة هب منصة إلكترونية مصرية تجمع الناس في مكان واحد لعرض المنتجات والبحث عنها وبيعها وشرائها. نؤمن أن الشيء الذي لم تعد تحتاجه قد يكون مفيدًا لشخص آخر، وأن الوصول إليه يجب أن يكون أسهل وأكثر تنظيمًا.',
          ),
          _section(
            context,
            title: 'ماذا تجد على كنزة هب؟',
            body:
                'تبدأ المنصة بمستلزمات الأطفال والمنزل والملابس والأحذية، مع إتاحة المنتجات الجديدة أو التي سبق اقتناؤها. ونعمل على تطوير تجربة عرض المنتجات واكتشافها والتواصل حولها بصورة تدريجية.',
          ),
          _section(
            context,
            title: 'كيف تعمل المنصة؟',
            body:
                'يمكن للزائر تصفح المنتجات المتاحة. ويتطلب البيع أو استخدام خصائص الحساب تسجيل الدخول. يضيف البائع بيانات المنتج وصوره وسعره، ثم يراجع المشتري التفاصيل ويتواصل أو يتابع خطوات الشراء المتاحة داخل التطبيق.',
          ),
          _section(
            context,
            title: 'رسالتنا',
            body:
                'تقديم سوق إلكتروني بسيط ومنظم يساعد على إعادة الاستفادة من المنتجات، ويمنح الأفراد والبائعين مساحة واضحة لعرض ما يقدمونه والوصول إلى المهتمين.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _red.withOpacity(0.18)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_outline, color: _red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'كنزة هب تكبر بمشاركة مجتمعها. شكرًا لكونك جزءًا من فكرتنا.',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'كنزة هب © جميع الحقوق محفوظة',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _section(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.8,
                  color: const Color(0xFF475569),
                ),
          ),
        ],
      ),
    );
  }
}
