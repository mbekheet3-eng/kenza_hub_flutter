# كينزا هب - Kenza Hub (Flutter)

**Marketplace for buying/selling Stock and used clothes in Egypt**

نسخة Dart/Flutter الكاملة لتطبيق كينزا هب - سوق إلكتروني لبيع وشراء الملابس الاستوك و المستعملة في مصر.

## 📱 المميزات الأساسية

✅ **Sell Wizard** - معالج بيع سهل مع 8 خطوات:
  - اختيار الصور (حتى 8 صور)
  - تحديد الفئة
  - تحديد الحالة والمقاس واللون
  - اختيار العلامة التجارية
  - إضافة الوصف والعنوان
  - تحديد السعر
  - مراجعة النهائية

✅ **Image Upload Service** - نظام رفع الصور محسّن:
  - دعم كامل لـ Android (معالجة صحيحة للـ URIs)
  - ذاكرة التخزين المؤقت (Cache Directory)
  - كشف نوع الملف من headers
  - تحديد حد أقصى 8 صور

✅ **Search & Browse** - البحث والاستعراض:
  - البحث بالكلمات المفتاحية
  - الفلاتر (الفئة، السعر)
  - عرض المنتجات الرائجة

✅ **Authentication** - المصادقة:
  - تسجيل الدخول والتسجيل
  - تكامل Supabase Auth

✅ **Database Integration** - التكامل مع قاعدة البيانات:
  - Supabase PostgreSQL
  - جداول كاملة (products, users, orders)

## 🔧 التقنيات المستخدمة

- **Flutter 3.10+** - إطار العمل الأساسي
- **Dart** - لغة البرمجة
- **Supabase** - Backend + Storage + Auth
- **Riverpod** - إدارة الحالة
- **Go Router** - التنقل
- **Image Picker** - اختيار الصور
- **Cached Network Image** - تخزين الصور مؤقتاً

## 📦 البنية

```
lib/
├── main.dart
├── config/
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── product.dart
│   ├── user.dart
│   └── order.dart
├── services/
│   ├── supabase_service.dart
│   └── upload_service.dart
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── sell/
│   │   ├── sell_wizard_screen.dart
│   │   └── steps/
│   │       ├── step_images.dart
│   │       ├── step_category.dart
│   │       ├── step_brand.dart
│   │       ├── step_details.dart
│   │       └── step_price.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── product/
│   │   └── product_detail_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── orders/
│   │   └── orders_screen.dart
│   └── auth/
│       ├── login_screen.dart
│       └── signup_screen.dart
└── widgets/
```

## 🚀 البدء السريع

### المتطلبات
- Flutter 3.10+
- Dart 3.0+
- Android SDK (أو iOS SDK)
- حساب Supabase

### التثبيت

1. **استنساخ المستودع:**
```bash
git clone https://github.com/yourusername/kenza_hub_flutter.git
cd kenza_hub_flutter
```

2. **تثبيت الـ dependencies:**
```bash
flutter pub get
```

3. **إعداد ملف .env:**
```bash
cp .env.example .env
# عدّل القيم بحسب مشروعك على Supabase
```

4. **تشغيل التطبيق:**
```bash
flutter run
```

## 📋 جداول Supabase

### Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category VARCHAR(50) NOT NULL,
  condition VARCHAR(50) NOT NULL,
  color VARCHAR(50),
  size VARCHAR(50),
  brand VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  is_sold BOOLEAN DEFAULT false,
  views INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Product Images Table
```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY,
  product_id UUID NOT NULL REFERENCES products(id),
  image_url TEXT NOT NULL,
  local_path TEXT,
  order INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  phone VARCHAR(20),
  avatar_url TEXT,
  bio TEXT,
  location VARCHAR(255),
  rating DECIMAL(3, 2) DEFAULT 0,
  total_reviews INT DEFAULT 0,
  products_count INT DEFAULT 0,
  followers_count INT DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Orders Table
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  product_id UUID NOT NULL REFERENCES products(id),
  buyer_id UUID NOT NULL REFERENCES users(id),
  seller_id UUID NOT NULL REFERENCES users(id),
  amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  tracking_number VARCHAR(100),
  shipping_address TEXT,
  rating DECIMAL(3, 2),
  review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## 🔑 متغيرات البيئة

```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
APP_NAME=كينزا هب
```

## 📷 نظام رفع الصور

### المميزات:
- ✅ دعم كامل لـ Android (معالجة صحيحة للـ content:// URIs)
- ✅ ذاكرة التخزين المؤقت (Cache Directory)
- ✅ كشف نوع الملف من file headers (magic bytes)
- ✅ تحديد حد أقصى 8 صور
- ✅ معالجة الأخطاء الشاملة
- ✅ تتبع التقدم (Progress tracking)

### الخطوات:
1. اختيار صور من المعرض أو التقاط من الكاميرا
2. نسخ إلى cache directory
3. رفع إلى Supabase Storage
4. حفظ URLs في قاعدة البيانات
5. تنظيف cache

## 🎨 التصميم

- **Poppins Font** - للنصوص الإنجليزية
- **Cairo Font** - للنصوص العربية
- **Color Scheme** - ألوان حديثة وجذابة
- **Material Design 3** - تصميم حديث

## 🐛 معالجة الأخطاء

تم حل مشكلة رفع الصور على Android:
- ✅ معالجة صحيحة لـ URIs المختلفة
- ✅ كشف تلقائي لنوع الملف من headers
- ✅ fallback إلى .jpg كخيار أخير
- ✅ تتبع تفصيلي للأخطاء

## 📝 الترجمة

التطبيق يدعم:
- العربية (RTL)
- الإنجليزية (LTR)

## 🔒 الأمان

- Supabase Auth للمصادقة الآمنة
- Row-level Security (RLS) على قاعدة البيانات
- Validation على جميع الـ inputs
- HTTPS لجميع الطلبات

## 🚦 حالة المشروع

- ✅ Sell Wizard - مكتمل 100%
- ✅ Image Upload Service - مكتمل 100%
- ✅ Home Screen - مكتمل 100%
- ✅ Search Screen - مكتمل 100%
- 🟡 Product Detail - تطوير قيد الإجراء
- 🟡 Profile - تطوير قيد الإجراء
- 🟡 Orders - تطوير قيد الإجراء
- 🟡 Payment Integration - قادم

## 📊 الخطوات التالية

1. **Authentication كاملة** - Supabase Auth integration
2. **Product Detail Screen** - عرض تفاصيل المنتج الكاملة
3. **Payment Integration** - نظام الدفع
4. **Order Management** - إدارة الطلبات
5. **User Profile** - ملف المستخدم الشخصي
6. **Notifications** - الإشعارات
7. **Reviews & Ratings** - التقييمات والتعليقات
8. **Message System** - نظام الرسائل

## 🤝 المساهمة

يمكنك المساهمة بـ:
- الإبلاغ عن الأخطاء
- تقديم اقتراحات
- إرسال Pull Requests

## 📄 الترخيص

هذا المشروع مرخص تحت MIT License

## 👨‍💻 المطور

تم تطويره بواسطة **AI Claude**

## 📧 التواصل

للأسئلة والاستفسارات:
- GitHub Issues
- Email: support@kenzahub.com

---

**تم آخر تحديث:** July 2026 (Flutter Version)
