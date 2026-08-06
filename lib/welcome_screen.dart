import 'package:flutter/material.dart';
import 'dart:async';

// -----------------------------------------------
//  نموذج بسيط لإدارة اللغة (بدون حزم خارجية)
// -----------------------------------------------
class LanguageManager extends ChangeNotifier {
  Locale _locale = Locale('ar'); // العربية افتراضياً
  Locale get locale => _locale;

  void setLanguage(String langCode) {
    _locale = Locale(langCode);
    notifyListeners();
  }
}

// -----------------------------------------------
//  الـ Widget الرئيسي للشاشة
// -----------------------------------------------
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // مدير اللغة
  final LanguageManager _languageManager = LanguageManager();

  // القواميس الخاصة بكل لغة (النصوص)
  Map<String, String> get texts {
    final lang = _languageManager.locale.languageCode;
    switch (lang) {
      case 'en':
        return {
          'header': 'Join and sell pre-loved items with no fees',
          'signup': 'Sign up for Vinted',
          'have_account': 'I already have an account',
          'browse': 'Browse as guest',
          'about': 'About Vinted: Our platform',
        };
      case 'fr':
        return {
          'header': 'Rejoignez et vendez des articles d\'occasion sans frais',
          'signup': 'S\'inscrire sur Vinted',
          'have_account': 'J\'ai déjà un compte',
          'browse': 'Parcourir en tant qu\'invité',
          'about': 'À propos de Vinted : Notre plateforme',
        };
      default: // العربية
        return {
          'header': 'انضم وبع أغراضك المستعملة بدون عمولات',
          'signup': 'التسجيل كمستخدم جديد',
          'have_account': 'لدي حساب بالفعل',
          'browse': 'التصفح كزائر',
          'about': 'من نحن: منصتنا',
        };
    }
  }

  // قوائم الصور (ضع هنا مسارات صورك الفعلية)
  final List<String> imageList1 = List.generate(12, (i) => 'https://picsum.photos/seed/$i/200/200');
  final List<String> imageList2 = List.generate(12, (i) => 'https://picsum.photos/seed/${i+100}/200/200');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageManager,
      builder: (context, _) {
        final t = texts;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // -------- مفتاح تبديل اللغات (أعلى يسار) --------
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _languageButton('عربي', 'ar'),
                        const SizedBox(width: 8),
                        _languageButton('English', 'en'),
                        const SizedBox(width: 8),
                        _languageButton('Français', 'fr'),
                      ],
                    ),
                  ),
                ),
                // -------- الصفين المتحركين (مع مسافة بينهم) --------
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: InfiniteScrollRow(
                          images: imageList1,
                          direction: Axis.horizontal,
                          reverse: false, // يتحرك لليمين
                          speed: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: InfiniteScrollRow(
                          images: imageList2,
                          direction: Axis.horizontal,
                          reverse: true, // يتحرك لليسار
                          speed: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                // -------- النص الرئيسي (الهيدر) --------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    t['header']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50), // كحلي غامق
                    ),
                  ),
                ),
                // -------- الأزرار الثلاثة --------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildButton(t['signup']!, () {
                        // تسجيل جديد
                      }),
                      const SizedBox(height: 12),
                      _buildButton(t['have_account']!, () {
                        // تسجيل الدخول
                      }, isOutlined: true),
                      const SizedBox(height: 12),
                      _buildButton(t['browse']!, () {
                        // تصفح كزائر
                      }, isOutlined: true),
                    ],
                  ),
                ),
                // -------- رابط "من نحن" في الأسفل --------
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: GestureDetector(
                    onTap: () {
                      // اذهب لصفحة "من نحن"
                    },
                    child: Text(
                      t['about']!,
                      style: TextStyle(
                        color: const Color(0xFF2C3E50),
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // زر اللغة المصغر
  Widget _languageButton(String label, String code) {
    final isSelected = _languageManager.locale.languageCode == code;
    return GestureDetector(
      onTap: () => _languageManager.setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // زر رئيسي
  Widget _buildButton(String label, VoidCallback onTap, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : Colors.red,
          foregroundColor: isOutlined ? Colors.red : Colors.white,
          side: BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// -----------------------------------------------
//  Widget خاص بالتمرير اللانهائي للصف
// -----------------------------------------------
class InfiniteScrollRow extends StatefulWidget {
  final List<String> images;
  final Axis direction;
  final bool reverse; // true = يتحرك عكس الاتجاه
  final double speed; // سرعة الحركة

  const InfiniteScrollRow({
    super.key,
    required this.images,
    this.direction = Axis.horizontal,
    this.reverse = false,
    this.speed = 1.0,
  });

  @override
  State<InfiniteScrollRow> createState() => _InfiniteScrollRowState();
}

class _InfiniteScrollRowState extends State<InfiniteScrollRow>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _position = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10),
    )..addListener(() {
        // نحرك الموضع باستمرار
        _position += (widget.reverse ? -1 : 1) * widget.speed * 0.5;
        // نحافظ على القيمة ضمن حدود معينة لضمان اللانهائية
        // سنقوم بلف الصور عن طريق مضاعفة القائمة وتكرارها
        setState(() {});
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نضاعف القائمة لتظهر بشكل متصل
    final duplicatedList = List.from(widget.images)..addAll(widget.images);
    // نأخذ عرض الـ Container عن طريق LayoutBuilder لنحسب الإزاحة
    return LayoutBuilder(
      builder: (context, constraints) {
        // نحسب عرض العنصر الواحد (كل صورة بعرض 100 مثلاً)
        // نستخدم Image.network لكن يمكن استبدالها بـ Image.asset
        // نضع كل صورة في Container بعرض ثابت
        final imageWidth = 120.0; // يمكن ضبطه
        final totalWidth = duplicatedList.length * imageWidth;
        // نحسب الإزاحة المعيارية بحيث تتراوح بين 0 و totalWidth/2
        double offset = _position % (totalWidth / 2);
        // إذا كانت الإزاحة سالبة نعدلها
        if (offset < 0) offset += totalWidth / 2;
        // نحول الإزاحة إلى إزاحة حقيقية
        double translateX = -offset;
        // نعيد تعيين الموضع إذا وصل للنهاية بطريقة غير محسوسة
        // (الـ modulo يكفل الاستمرارية)
        return ClipRect(
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(translateX, 0),
                child: Row(
                  children: duplicatedList.map((url) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: imageWidth,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: imageWidth,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
