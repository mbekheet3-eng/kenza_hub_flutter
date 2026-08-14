import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controllerRow1;
  late AnimationController _controllerRow2;
  String _currentLanguage = 'ar';

  // قائمة الصور للصف الأول (تتحرك → يمين)
  final List<String> _row1Images = [
    'assets/images/welcome/welcome_row1_01.png',
    'assets/images/welcome/welcome_row1_02.png',
    'assets/images/welcome/welcome_row1_03.png',
    'assets/images/welcome/welcome_row1_04.png',
    'assets/images/welcome/welcome_row1_05.png',
    'assets/images/welcome/welcome_row1_06.png',
    'assets/images/welcome/welcome_row1_07.png',
    'assets/images/welcome/welcome_row1_08.png',
    'assets/images/welcome/welcome_row1_09.png',
    'assets/images/welcome/welcome_row1_10.png',
  ];

  // قائمة الصور للصف الثاني (تتحرك ← يسار)
  final List<String> _row2Images = [
    'assets/images/welcome/welcome_row2_01.png',
    'assets/images/welcome/welcome_row2_02.png',
    'assets/images/welcome/welcome_row2_03.png',
    'assets/images/welcome/welcome_row2_04.png',
    'assets/images/welcome/welcome_row2_05.png',
    'assets/images/welcome/welcome_row2_06.png',
    'assets/images/welcome/welcome_row2_07.png',
    'assets/images/welcome/welcome_row2_08.png',
    'assets/images/welcome/welcome_row2_09.png',
    'assets/images/welcome/welcome_row2_10.png',
  ];

  @override
  void initState() {
    super.initState();
    // الصف الأول يتحرك بسرعة متوسطة (→)
    _controllerRow1 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // الصف الثاني يتحرك بسرعة مختلفة ومعاكسة (←)
    _controllerRow2 = AnimationController(
      duration: const Duration(seconds: 35),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controllerRow1.dispose();
    _controllerRow2.dispose();
    super.dispose();
  }

  // بناء صف متحرك من الصور
  Widget _buildImageRow(AnimationController controller, List<String> images, bool reverse) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(controller.value * 200, 0),
          child: SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length * 3, // تكرار لا نهائي
              itemBuilder: (context, index) {
                final imageIndex = index % images.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      images[imageIndex],
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== 1. Language Selector + Logo =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // لوجو + اسم التطبيق
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'K',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Kenza Hub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  // أزرار اللغة
                  Row(
                    children: [
                      _buildLanguageButton('AR'),
                      const SizedBox(width: 4),
                      _buildLanguageButton('EN'),
                      const SizedBox(width: 4),
                      _buildLanguageButton('FR'),
                    ],
                  ),
                ],
              ),
            ),

            // ===== 2. الصفان المتحركان =====
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الصف الأول (→ اتجاه)
                  _buildImageRow(_controllerRow1, _row1Images, false),
                  const SizedBox(height: 10),
                  // الصف الثاني (← اتجاه معاكس)
                  _buildImageRow(_controllerRow2, _row2Images, true),
                ],
              ),
            ),

            // ===== 3. النصوص والأزرار =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Column(
                children: [
                  // Headline
                  const Text(
                    'لو مش محتاجها...\nغيرك محتاجها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  const Text(
                    'بيع واشتري بسهولة من غير عمولة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA - إنشاء حساب
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary CTA - تسجيل الدخول
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // تصفح كزائر
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/guest_home');
                    },
                    child: const Text(
                      'التصفح كزائر',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== 4. الفوتر =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _footerLink('من نحن'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                      ),
                      _footerLink('الشروط والأحكام'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                      ),
                      _footerLink('سياسة الخصوصية'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String code) {
    final isSelected = _currentLanguage == code.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentLanguage = code.toLowerCase();
        });
        // هنا ستضيف تغيير اللغة الفعلي لاحقاً مع Localization
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC62828) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC62828) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text - قيد التطوير'),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}