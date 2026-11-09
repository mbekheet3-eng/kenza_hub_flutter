import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  static const sections = <(String, String)>[
    ('1. الحساب وأمنه', 'قدّم بيانات صحيحة، وحافظ على سرية كلمة المرور ورموز التحقق. لا تشارك بيانات الدخول مع أي شخص.'),
    ('2. عرض المنتجات', 'يجب أن تكون المنتجات قانونية ومسموحًا بعرضها، وأن تكون الصور والوصف والسعر معبرة عنها بصدق. يحظر نشر المنتجات المقلدة أو المسروقة أو المحظورة أو المحتوى المضلل.'),
    ('3. مسؤولية البائع', 'البائع مسؤول عن ملكية المنتج وصحة وصفه وحالته وصوره، وعن توضيح العيوب والمعلومات التي تؤثر في قرار الشراء.'),
    ('4. مسؤولية المشتري', 'على المشتري مراجعة الصور والوصف والسعر وطرح الأسئلة اللازمة قبل الاتفاق. لا ترسل كلمة المرور أو رموز التحقق لأي شخص.'),
    ('5. الشحن والتسليم', 'تختلف خيارات التسليم حسب المناطق المتاحة والاتفاق بين الطرفين. يجب تأكيد وسيلة التسليم والتكلفة والمدة قبل إتمام الاتفاق.'),
    ('6. الأسعار والمدفوعات', 'السعر يحدده البائع. لا تفترض توافر دفع إلكتروني أو ضمان مالي ما لم يظهر ذلك صراحة في مسار رسمي داخل التطبيق.'),
    ('7. الخصوصية', 'تُستخدم بيانات الحساب لتشغيل الخدمة. لا تنشر أرقام الهواتف أو العناوين أو المستندات الخاصة في وصف المنتج أو الصور، ولا تحاول الوصول إلى بيانات مستخدم آخر.'),
    ('8. إساءة الاستخدام', 'يحظر الاحتيال وانتحال الصفة والتحرش والتلاعب ومحاولات اختراق التطبيق أو تعطيل خدماته. يجوز تقييد الحساب أو إزالة المحتوى المخالف.'),
    ('9. دور كنزة هب', 'كنزة هب منصة لعرض المنتجات وربط المستخدمين، وليست مالكًا للمنتجات المعروضة. يظل كل بائع مسؤولًا عن المنتج الذي ينشره.'),
    ('10. التحديثات والتواصل', 'قد تُحدّث هذه الأحكام مع تطور الخدمة. هذه نسخة تشغيلية أولية للاختبار الداخلي وليست بديلًا عن المراجعة القانونية وإشعار الخصوصية النهائي قبل الإطلاق العام.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الشروط والسياسات')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
          child: const Text('يرجى قراءة الأحكام التالية قبل استخدام كنزة هب.', style: TextStyle(color: Colors.white, height: 1.7)),
        ),
        const SizedBox(height: 12),
        ...sections.map((section) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(section.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [Align(alignment: AlignmentDirectional.centerStart, child: Text(section.$2, style: const TextStyle(height: 1.8, color: Color(0xFF475569))))],
          ),
        )),
      ],
    ),
  );
}
