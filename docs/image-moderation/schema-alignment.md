# ربط نظام فحص الصور بمخطط Supabase الفعلي

**الحالة:** فحص قراءة فقط + تصميم متوافق مع المخطط الحالي. لا SQL منفذ، لا migration مطبقة، ولا تغيير في إعدادات Storage أو API.

## 1) ما تم التحقق منه مباشرة

المشروع: `qvqfzujvcnmquohieevl`، PostgreSQL 17.6.

### الجداول والحقول الحالية ذات الصلة

- `public.product_images`: `id UUID`, `product_id UUID`, `image_url TEXT`, `display_order INTEGER`, `created_at`.
- `public.products`: `id`, `seller_id`, `category_id`, `status_id`، العنوان والوصف والسعر، وباقي الحقول الحالية.
- `public.users`: يحتوي `avatar_url`.
- `public.seller_profiles`: يحتوي `avatar_url` و`owner_user_id`.
- `public.product_statuses` يتضمن الحالات `active`, `pending`, `rejected`, `hidden`, `deleted`, `reserved`, `sold`.
- RLS مفعّل على الجداول الحالية التي فُحصت.

### وضع التخزين الحالي — مانع أمني يجب حله

- Bucket `product-images` موجود، وحالته `public = true`.
- حد الحجم الحالي 10 MiB، وأنواع الصور المسموحة JPEG وPNG وWebP.
- سياسة `product_images_public_read` تسمح بالقراءة العامة من هذا الـ bucket.
- سياسة `product_images_authenticated_upload` تسمح للمستخدم المسجل برفع الملفات إلى `products/%`.
- خدمة Flutter الحالية `lib/services/upload_service.dart` ترفع الصورة مباشرة إلى هذا الـ bucket ثم تستخرج Public URL.
- دالة `uploadProfileImage` تستخدم نفس الـ bucket ومساراً يبدأ بـ `products/{userId}/profile/`.
- `MarketplaceProductService.createProduct` ينشئ المنتج بحالة `active` ثم يضيف صفوف `product_images`.
- وقت الفحص، عدد صفوف `products` و`product_images` كان صفراً. لا نفترض أن بيانات الحسابات أو الصور الشخصية خالية؛ لم نعتمد على ذلك.

**النتيجة:** لا يمكن اعتبار الرفع الحالي آمناً للفحص المسبق؛ لأن الصورة في الـ bucket العام تصبح قابلة للعرض بمجرد رفعها، قبل استدعاء أي فاحص. كما أن الإبقاء على سياسة الرفع المباشر يتيح تجاوز Edge Function.

## 2) التصميم المتوافق مع الوضع الحالي

### A. لا نغيّر الـ bucket العام الحالي مباشرة

نُبقي `product-images` للصور المقبولة المنشورة حتى لا نكسر روابط الصور القديمة أو آلية العرض الحالية أثناء الانتقال.

نضيف bucket جديداً باسم مبدئي `image-quarantine`:
- Private وليس Public.
- لا يُسمح بعرض ملفاته عبر Public URL.
- الرفع يكون إلى مجلد خاص بالمستخدم، مثل `{auth.uid()}/{upload_uuid}.jpg`.
- يسمح للمستخدم برفع ملفه فقط، ولا يسمح له بنقله إلى bucket النشر أو اعتماد نتيجة الفحص.
- الوصول إلى ملفات الحجر للمعالجة يكون من Edge Function موثوقة فقط باستخدام secret server-side.
- لا يحتاج التطبيق إلى رابط عام أو signed URL للصورة المعلقة؛ المعاينة تكون من الملف المحلي على الهاتف.

### B. مسار الرفع الجديد

1. Flutter يتحقق مبدئياً من الملف (الحجم، MIME الحقيقي، الامتداد) ويعرض المعاينة المحلية.
2. يرفع الملف إلى `image-quarantine` الخاص.
3. يستدعي Edge Function باسم `image-moderation` مع معرّف الرفع/المسار، لا مع رابط عام.
4. تتحقق الوظيفة من JWT وملكية الملف، ثم تقرأه من bucket الخاص.
5. ترسل bytes إلى Gemini من الخادم فقط، بعد تجهيز إعدادات الخصوصية والموافقة على الإرسال الخارجي.
6. تطبق قواعد المنصة على نتيجة Gemini وتقرر: قبول، رفض، مراجعة، أو طلب صورة أوضح.
7. عند القبول فقط، تنقل الوظيفة الملف إلى `product-images` وتعيد مرجع الصورة المقبولة.
8. عند الرفض أو المراجعة أو الفشل، لا تنقل الملف ولا تنشئ Public URL. يبقى الملف غير متاح للعامة ويُحذف وفق سياسة الاحتفاظ.
9. لا يفعّل التطبيق المنتج قبل إضافة كل صور المنتج المقبولة.

### C. لماذا لا نجعل bucket الحالي Private؟

لأن `product-images` يحتوي/قد يحتوي روابط مستخدمة بالفعل في التطبيق، كما أن الكود الحالي يعتمد على `getPublicUrl`. تحويله مباشرة إلى Private قد يكسر عرض الصور الحالية. فصل الحجر عن النشر أقل خطراً، ثم يمكن لاحقاً دراسة توحيد التخزين في مشروع مستقل.

## 3) تصميم سجل الفحص

نقترح جدولين داخليين في قاعدة البيانات، دون منح `anon` أو `authenticated` أي صلاحية مباشرة عليهما:

### `public.image_moderation_reviews`

حقول مفاهيمية:
- `id UUID PK`.
- `owner_user_id UUID NOT NULL REFERENCES public.users(id)`.
- `image_purpose TEXT`: `product` أو `profile` أو نوع صورة آخر معتمد.
- `status TEXT`: `processing`, `approved`, `rejected`, `needs_review`, `needs_better_image`, `failed`.
- `quarantine_path TEXT NOT NULL UNIQUE`.
- `approved_object_path TEXT NULL UNIQUE`.
- `sha256 TEXT NOT NULL`، `mime_type TEXT`, `size_bytes BIGINT`.
- `provider_key TEXT`, `model_key TEXT`, `policy_version TEXT`.
- `safety_result JSONB`, `quality_result JSONB`, `relevance_result JSONB` (ملخصات منظمة ومحدودة، لا تفكير داخلي للنموذج).
- `reason_code TEXT`, `member_message_key TEXT`.
- `created_at`, `updated_at`, `reviewed_at`, `reviewed_by UUID NULL`.

### `public.image_moderation_events`

سجل تدقيق append-only:
- `id UUID PK`, `review_id UUID FK`.
- `event_type TEXT`, `actor_user_id UUID NULL`.
- `from_status TEXT NULL`, `to_status TEXT`.
- `reason_code TEXT NULL`, `metadata JSONB` منقحة وخالية من الصور والأسرار.
- `created_at`.

ضوابط:
- RLS مفعّل على الجدولين.
- لا منح مباشر لـ `anon` أو `authenticated`.
- تمنح صلاحيات التنفيذ اللازمة فقط لخدمة الخادم الموثوقة/دور `service_role`، بعد اختبار الوصول.
- لا تخزن الصور أو API keys أو signed URLs في سجل الأحداث.
- لا تُعرض تفاصيل تصنيفات حساسة للأعضاء؛ تعرض رسالة عربية مناسبة فقط.

> الجدولان في `public` هنا اختيار تصميمي لتوافق مسار Edge Function عبر Data API. قبل الإنشاء يجب التحقق من إعداد Exposed Schemas وGRANTs الفعلية. تحديث Supabase بتاريخ 30 أكتوبر 2026 غيّر الإتاحة التلقائية للجداول الجديدة في public؛ لذلك لا نفترض أن وجود الجدول وحده يجعله متاحاً عبر Data API. لا نفتح صلاحيات عامة لمجرد حل ذلك.

## 4) ربط الموافقة بجداول التطبيق الحالية

### صور المنتجات

- إضافة `moderation_review_id UUID` إلى `public.product_images` مع FK إلى سجل الفحص.
- Trigger قبل INSERT/UPDATE يتحقق من أن المراجعة:
  - حالتها `approved`.
  - غرضها `product`.
  - تخص المستخدم صاحب العملية.
  - مرتبطة بالمسار النهائي المعتمد للصورة.
- تضييق سياسة INSERT الحالية بحيث لا يستطيع العميل إضافة صورة لا ترتبط بمراجعة مقبولة.
- إزالة الرفع المباشر من العميل إلى bucket النشر؛ Edge Function وحدها تنقل الصور المقبولة إليه.
- لا يدخل أي ملف غير معتمد إلى صور المنتج أو فهرس البحث البصري.

### صور الحساب

- ربط تحديث `users.avatar_url` و`seller_profiles.avatar_url` بمراجعة مقبولة من النوع `profile`.
- الأفضل إضافة مرجع مراجعة صريح إلى سجلات الحساب/البائع أو التحقق داخل Trigger من المسار النهائي الموافق عليه؛ نختار النهج بعد مراجعة كل مسارات تعديل الصورة الشخصية في Flutter.
- لا نغيّر صور الحساب الموجودة أثناء migration، ولا نرفض قيمة قديمة لمجرد أنها لم تمر بالنظام الجديد. التحقق يطبق على تغيير الصورة من تاريخ تفعيل النظام.

### تفعيل المنتج

- يوجد بالفعل status باسم `pending` في جدول `product_statuses`.
- ندرس جعل إنشاء المنتج يبدأ بـ `pending` ثم الانتقال إلى `active` بعد اكتمال صفوف الصور المقبولة.
- نضيف تحققاً خادمياً يمنع تحويل المنتج إلى `active` إذا لم يكن له الحد الأدنى المطلوب من الصور المقبولة.
- لا نعتمد على Flutter وحده في فرض هذا الشرط؛ يجب أن يمنعه Trigger/RPC أو صلاحيات قاعدة البيانات أيضاً.

## 5) Edge Function: مسؤوليات وحدود

اسم مقترح: `image-moderation`.

- `verify_jwt = true` للطلبات القادمة من التطبيق.
- لا تقبل function رابط صورة arbitrary من المستخدم؛ تقبل review ID أو path تتحقق من ملكيته.
- لا تقبل قرار `approved` من Flutter؛ القرار يصدر من الخادم فقط.
- Gemini API key في Secrets فقط، ولا يضاف إلى المستودع أو التطبيق.
- استخدام استجابة JSON منظمة ومخطط تحقق صارم.
- المهلة أو الخطأ أو الاستجابة غير الصالحة = `failed` أو `needs_review`، ولا يتم النشر.
- Rate limits وحدود للحجم والأبعاد والطلبات.
- لا تسجل bytes الصورة أو محتواها أو مفاتيح المزود.
- نقل الملف إلى bucket العام يحدث بعد القبول فقط.
- إزالة الملفات المعلقة/المرفوضة بعد فترة احتفاظ قصيرة محددة، مع مراعاة إمكانية إعادة المحاولة والمراجعة.

## 6) خطة migrations المحلية المقترحة

لا ننشئ ملف migration يدوياً بأرقام تاريخية غير متحققة. وفق تعليمات Supabase CLI، يُنشأ كل ملف من الأمر `supabase migration new <descriptive_name>` محلياً ثم يملأ SQL بعد المراجعة.

ترتيب مقترح:
1. `create_image_moderation_storage`: إنشاء bucket الخاص وسياسات الحجر فقط.
2. `create_image_moderation_records`: إنشاء سجل المراجعات والأحداث والقيود والفهارس وRLS/GRANTs.
3. `enforce_approved_product_images`: إضافة مرجع المراجعة إلى `product_images`، والتحقق من الموافقة، وحماية انتقال المنتج إلى `active`.
4. `enforce_approved_profile_images`: حماية تغيير صور الحساب والبائع بعد تحديد مسارات Flutter الحالية بدقة.

كل migration تُختبر منفردة على قاعدة محلية منفصلة. لا تستخدم `apply_migration` على مشروع الإنتاج، ولا تنفذ أي SQL هنا.

## 7) نقاط فنية إضافية تم التحقق منها

- امتداد `vector` متاح كحزمة على المنصة لكن غير مثبت في قاعدة المشروع حالياً؛ لا نثبته ضمن فحص الصور.
- البحث البصري مستقل عن moderation. لا تدخل إلا صور المنتجات المقبولة في فهرس embeddings.
- لا يوجد Edge Function باسم `image-moderation` حالياً؛ الوظائف المنشورة الموجودة هي `seller-profile-create` و`order-create`.
- قاعدة الإنتاج لم تتغير أثناء هذا الفحص.

## 8) ما يلزم قبل كتابة migrations قابلة للتطبيق

1. تشغيل Supabase CLI محلياً على Windows وقراءة `supabase --version` و`supabase migration new --help`.
2. سحب/مزامنة مخطط المشروع في بيئة محلية منفصلة والتحقق من migrations المحلية مقابل سجل الإنتاج؛ لا نستخدم قاعدة الإنتاج كبيئة تجارب.
3. مراجعة كل مواضع رفع وتحديث صورة الحساب في Flutter قبل إضافة القيود.
4. اعتماد فترة الاحتفاظ بالصور المرفوضة/المعلقة ورسائل الرفض.
5. اعتماد شروط Google وسياسة معالجة الصور قبل وضع Gemini API key أو إرسال أي صورة فعلية.

**حدود هذه الوثيقة:** تصميم مبني على قراءة فعلية للمخطط والسياسات، وليس SQL جاهزاً للتشغيل. لم يتم إنشاء bucket، أو جدول، أو trigger، أو function، ولم يتم إرسال أي صورة إلى Google.
