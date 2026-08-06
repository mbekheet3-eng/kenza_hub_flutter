import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // سيتم إضافة الهيدر هنا
            const SizedBox(height: 16),

            // سيتم إضافة صفوف الصور هنا
            const Spacer(),

            // سيتم إضافة العنوان هنا
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: const [
                  Text(
                    'لو مش محتاجها... غيرك محتاجها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'بيع واشتري بسهولة من غير عمولة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // سيتم إضافة الأزرار هنا

            const SizedBox(height: 32),

            // سيتم إضافة الروابط السفلية هنا

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
