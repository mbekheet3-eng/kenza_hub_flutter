import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  static const Color _red = Color(0xFFC62828);
  static const Color _navy = Color(0xFF0F172A);

  static const List<_PolicySection> _sections = [
    _PolicySection(
      title: '1. نطاق السياسة والموافقة',
      body:
          'تنظم هذه الصفحة استخدام تطبيق كنزة هب وخدماته. باستخدامك التطبيق أو إنشاء حساب أو عرض منتج، فإنك توافق على الالتزام بهذه الأحكام. إذا لم توافق عليها، يرجى التوقف عن استخدام الخدمات. قد تُحدّث السياسة عند تطوير المنصة، ويُعرض تاريخ آخر تحديث عند اعتماد النسخة النهائية.',
    ),
    _PolicySection(
      title: '2. طبيعة دور كنزة هب',
      body:
          'كنزة هب منصة إلكترونية لعرض المنتجات وربط البائعين بالمشترين، وليست مالكًا للمنتجات المعروضة ولا طرفًا في ملكيتها. يظل البائع مسؤولًا عن صحة وصف المنتج وحالته وملكيته ومشروعية عرضه، ويظل المشتري مسؤولًا عن مراجعة التفاصيل والاتفاق على ما يناسبه. لا يعني ظهور أي إعلان أن المنصة فحصت المنتج ماديًا أو ضمنت جودته.',
    ),
    _PolicySection(
      title: '3. الحساب وأمنه',
      body:
          'يجب تقديم بيانات صحيحة ومحدثة، والمحافظة على سرية بيانات الدخول، وعدم مشاركة الحساب أو استخدام حساب شخص آخر دون تصريح. يتحمل المستخدم مسؤولية الأنشطة التي تتم من خلال حسابه، وعليه إبلاغ المنصة عند الاشتباه في استخدام غير مصرح به. يجوز تقييد الحساب أو إيقافه عند إساءة الاستخدام أو مخالفة هذه السياسة، وفق الإجراءات المعتمدة.',
    ),
    _PolicySection(
      title: '4. قواعد عرض المنتجات',
      body:
          'يجب أن تكون المنتجات قانونية ومسموحًا بتداولها، وأن تكون الصور والوصف والسعر معبرة عنها بصدق. يُحظر نشر معلومات مضللة أو منتجات مقلدة أو مسروقة أو محظورة قانونًا، أو محتوى ينتهك حقوق الآخرين أو خصوصيتهم. يجب توضيح العيوب والحالة الفعلية وأي معلومات مؤثرة في قرار المشتري. تحتفظ المنصة بحق مراجعة أو إخفاء المحتوى المخالف.',
    ),
    _PolicySection(
      title: '5. مسؤوليات البائع',
      body:
          'يلتزم البائع بامتلاك حق التصرف في المنتج، وتقديم وصف وصور حقيقية، والرد بوضوح على استفسارات المشتري، والالتزام بما تم الاتفاق عليه بشأن السعر والحالة والتسليم. لا يجوز استخدام المنصة للتحايل أو نشر إعلانات متكررة مضللة أو نقل التعامل خارج المنصة بقصد الإضرار بالمستخدمين أو تجاوز ضوابطها.',
    ),
    _PolicySection(
      title: '6. مسؤوليات المشتري',
      body:
          'على المشتري قراءة الوصف ومراجعة الصور والحالة والسعر وتفاصيل التسليم قبل إتمام أي اتفاق. ينبغي التأكد من ملاءمة المنتج وطرح الأسئلة اللازمة والاحتفاظ بما يثبت الاتفاق والتواصل. لا ترسل كلمات المرور أو رموز التحقق أو بيانات مالية حساسة لأي شخص يدّعي تمثيل المنصة.',
    ),
    _PolicySection(
      title: '7. الشحن والتوصيل والتغطية',
      body:
          'تختلف خيارات التسليم بحسب عنوان الأطراف والخيارات المتاحة وقت الاتفاق. نطاق شبكة التوصيل الداخلية عند الإطلاق محدود بمناطق محددة في القاهرة والجيزة، تشمل المعادي والدقي والعجوزة والمهندسين ووسط البلد والمنيل والمناطق الملاصقة التي يتم تأكيد تغطيتها. قد يستطيع المستخدم التسجيل والتصفح من مناطق أخرى، لكن ذلك لا يعني توافر خدمة التوصيل الداخلي إليها. يجب مراجعة وسيلة الشحن والتكلفة والمدة والمسؤولية عن التسليم قبل الاتفاق.',
    ),
    _PolicySection(
      title: '8. الأسعار والعمولات والمدفوعات',
      body:
          'السعر المعروض يحدده البائع ما لم يُذكر خلاف ذلك. لا تفرض كنزة هب عمولة على البيع وفق سياسة الإطلاق المعلنة. لا تعتبر هذه العبارة وعدًا بتوافر بوابة دفع إلكتروني أو خدمة تحصيل أو ضمان مالي؛ وتُعلن أي وسيلة دفع أو رسوم إضافية بوضوح قبل تفعيلها. لا ترسل أموالًا إلى حسابات أو أشخاص غير موضحين في مسار رسمي معتمد.',
    ),
    _PolicySection(
      title: '9. الإلغاء والاسترجاع والنزاعات',
      body:
          'قبل التسليم، ينبغي للطرفين توثيق أي اتفاق على الإلغاء أو تعديل الطلب. لا تفترض وجود خدمة استرجاع أو استرداد أموال آلية ما لم تظهر شروطها صراحة في مسار شراء معتمد. عند حدوث خلاف، احتفظ بالمحادثات والصور وإثباتات التسليم، وتواصل مع قنوات الدعم الرسمية عند إتاحتها. لا تملك المنصة إصدار حكم نهائي في نزاع لا تتوافر له آلية مراجعة معتمدة.',
    ),
    _PolicySection(
      title: '10. الخصوصية والبيانات الشخصية',
      body:
          'تستخدم المنصة البيانات اللازمة لإنشاء الحساب وتشغيل الخصائص وتحسين الأمان وتقديم الدعم، وفق الأغراض المعلنة. لا تنشر بيانات الاتصال أو العنوان أو المستندات الخاصة في وصف المنتج أو الصور. قد تظهر بعض بيانات البائع العامة، مثل اسم العرض وتفاصيل المتجر، بحسب خصائص التطبيق. لا تشارك بيانات مستخدم آخر أو تحاول الوصول إلى حسابه أو بياناته دون إذن. يجب نشر إشعار خصوصية تفصيلي يحدد أنواع البيانات وأغراض المعالجة ومدد الاحتفاظ والجهات التي قد تتلقى البيانات ووسائل ممارسة الحقوق قبل الإطلاق العام.',
    ),
    _PolicySection(
      title: '11. المحتوى والملكية الفكرية',
      body:
          'يحتفظ المستخدم بحقوقه في المحتوى الذي يملكه، ويمنح المنصة الإذن اللازم لعرضه وتشغيله داخل الخدمة بالقدر المرتبط باستخدام التطبيق. لا يجوز نسخ العلامات أو الصور أو النصوص أو استخدام محتوى الغير دون حق أو إذن. ويجوز إزالة المحتوى عند وجود بلاغ جدي أو مخالفة واضحة.',
    ),
    _PolicySection(
      title: '12. إساءة الاستخدام والإيقاف',
      body:
          'يُحظر الاحتيال والتهديد والتحرش وانتحال الصفة والتلاعب بالتقييمات ومحاولات اختراق التطبيق أو تعطيل خدماته. قد تتخذ المنصة إجراءات متناسبة، مثل إزالة المحتوى أو تقييد بعض الخصائص أو تعليق الحساب أو إيقافه، مع مراعاة القوانين والحقوق واجبة التطبيق.',
    ),
    _PolicySection(
      title: '13. حدود المسؤولية',
      body:
          'تُقدّم المنصة كما هي وبحسب الخصائص المتاحة فعليًا، وتسعى إلى تحسين استقرارها ودقة المعلومات، لكنها لا تضمن خلو الخدمة من الانقطاع أو الأخطاء. لا تتحمل المنصة مسؤولية جودة منتج أو وصف يقدمه مستخدم آخر، ولا عن اتفاقات تتم خارج المسارات التي توفرها المنصة، وذلك دون الإخلال بأي مسؤولية لا يجوز استبعادها قانونًا.',
    ),
    _PolicySection(
      title: '14. القانون والتواصل',
      body:
          'تخضع هذه الأحكام للقوانين واللوائح واجبة التطبيق في جمهورية مصر العربية، بالقدر الذي لا يتعارض مع القواعد الآمرة. يجب توفير وسيلة تواصل رسمية واضحة لاستقبال الاستفسارات والشكاوى وطلبات الخصوصية قبل الإطلاق العام. لا تُعد هذه النسخة بديلًا عن المراجعة القانونية المتخصصة أو إشعار الخصوصية النهائي.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).policiesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.policy_outlined, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).policiesIntroTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).policiesIntro,
                  style: TextStyle(color: Colors.white70, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF9A3412)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).policiesDraftNotice,
                    style: TextStyle(
                      color: Color(0xFF7C2D12),
                      height: 1.6,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._sections.map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                iconColor: _red,
                collapsedIconColor: _navy,
                title: Text(
                  section.title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF475569),
                            height: 1.85,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppLocalizations.of(context).copyright,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
