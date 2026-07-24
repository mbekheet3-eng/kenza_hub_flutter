# 🏗️ Kenza Hub Flutter - Project Structure

## الهيكل الكامل للمشروع

```
kenza_hub_flutter/
│
├── lib/
│   ├── core/
│   │   ├── constants.dart          # ثوابت التطبيق
│   │   ├── failures.dart           # Failure classes للـ error handling
│   │   ├── exceptions.dart         # Custom exceptions
│   │   ├── result.dart             # Result type (Success/Failure)
│   │   ├── helpers.dart            # Helper functions
│   │   └── index.dart              # Core exports
│   │
│   ├── config/
│   │   ├── theme.dart              # Design system & colors
│   │   └── routes.dart             # Navigation configuration
│   │
│   ├── models/
│   │   ├── product.dart            # Product model
│   │   ├── user.dart               # User model
│   │   └── order.dart              # Order model
│   │
│   ├── services/
│   │   ├── supabase_service.dart   # Supabase operations
│   │   └── upload_service.dart     # Image upload & handling
│   │
│   ├── repositories/
│   │   └── product_repository.dart # Product repository (interface + impl)
│   │
│   ├── storage/
│   │   └── local_storage.dart      # Local storage (SharedPreferences)
│   │
│   ├── network/
│   │   └── network_info.dart       # Network connectivity check
│   │
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── sell/
│   │   │   ├── sell_wizard_screen.dart
│   │   │   └── steps/
│   │   │       ├── step_images.dart
│   │   │       ├── step_category.dart
│   │   │       ├── step_brand.dart
│   │   │       ├── step_details.dart
│   │   │       ├── step_price.dart
│   │   │       └── step_review.dart (في sell_wizard)
│   │   ├── search/
│   │   │   └── search_screen.dart
│   │   ├── product/
│   │   │   └── product_detail_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── orders/
│   │   │   └── orders_screen.dart
│   │   └── auth/
│   │       ├── login_screen.dart
│   │       └── signup_screen.dart
│   │
│   └── main.dart                    # Entry point
│
├── assets/
│   ├── images/                      # Images (جاهز للإضافة)
│   ├── icons/                       # Icons (جاهز للإضافة)
│   └── fonts/                       # Custom fonts (جاهز للإضافة)
│
├── test/                            # Unit & widget tests
│   ├── models/
│   ├── services/
│   ├── repositories/
│   └── screens/
│
├── android/                         # Android configuration
├── ios/                             # iOS configuration
├── web/                             # Web support (اختياري)
│
├── pubspec.yaml                     # Dependencies & configuration
├── analysis_options.yaml            # Dart analysis rules
├── .env.example                     # Environment template
├── .gitignore                       # Git ignore rules
│
└── Documentation/
    ├── README.md                    # Main documentation
    ├── SETUP.md                     # Setup guide
    ├── DATABASE_SCHEMA.md           # Database structure
    ├── ARCHITECTURE.md              # Architecture explanation
    ├── PROJECT_STRUCTURE.md         # هذا الملف
    └── PRE_COMMIT_CHECKLIST.md      # Verification checklist
```

## 📁 شرح كل مجلد

### 1. **lib/core/**
**الأساسيات المشتركة في المشروع**

- `constants.dart` - الثوابت العامة (max images, timeouts, إلخ)
- `failures.dart` - Failure classes للـ error handling
- `exceptions.dart` - Custom exceptions
- `result.dart` - Result type (Success/Failure) للعمليات غير المتزامنة
- `helpers.dart` - دوال مساعدة (String, Number, Date, Validation)
- `index.dart` - تصدير سهل للـ core

### 2. **lib/config/**
**إعدادات التطبيق**

- `theme.dart` - النظام البصري الكامل (Material Design 3)
- `routes.dart` - إعدادات التنقل (GoRouter)

### 3. **lib/models/**
**نماذج البيانات**

- `product.dart` - منتج مع JSON serialization
- `user.dart` - المستخدم
- `order.dart` - الطلب

### 4. **lib/services/**
**طبقة العمليات (Business Logic)**

- `supabase_service.dart` - الاتصال مباشرة مع Supabase
- `upload_service.dart` - معالجة رفع الصور

### 5. **lib/repositories/** ⭐ مهم!
**Pattern Repository - طبقة وسيطة بين Services و UI**

- `product_repository.dart` - واجهة + تطبيق
- يوفر error handling unified
- يحول exceptions إلى Results
- يسهل الـ testing

### 6. **lib/storage/**
**التخزين المحلي**

- `local_storage.dart` - SharedPreferences wrapper
- حفظ user preferences, cache, إلخ

### 7. **lib/network/**
**إدارة الاتصال (للمستقبل)**

- `network_info.dart` - التحقق من الاتصال بالإنترنت

### 8. **lib/screens/**
**واجهات المستخدم**

```
screens/
├── home/          # الصفحة الرئيسية
├── sell/          # معالج البيع (8 steps)
├── search/        # البحث والاستعراض
├── product/       # تفاصيل المنتج
├── profile/       # ملف المستخدم
├── orders/        # إدارة الطلبات
└── auth/          # تسجيل الدخول والتسجيل
```

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer (Screens)                  │
│         (يعرض البيانات ويتعامل مع الإدخال)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Repositories                          │
│    (معالجة الأخطاء، تحويل Exceptions إلى Results)     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                     Services                            │
│        (Supabase, Upload, Network Operations)          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Supabase Backend                      │
│         (Database, Storage, Authentication)             │
└─────────────────────────────────────────────────────────┘
```

## 🎯 مثال: Search Flow

```
SearchScreen (UI)
    ↓ يستدعي
ProductRepository.searchProducts()
    ↓ معالجة الأخطاء والتحويل
SupabaseService.searchProducts()
    ↓ استدعاء API
Supabase (Backend)
    ↓ النتيجة
Result<Success<List<Product>>>
    ↓ عرض في الـ UI
GridView with products
```

## 📊 Dependencies Structure

```
Screens ← Repositories ← Services ← Supabase
           ↓
         Storage
           ↓
      SharedPreferences
           
Core (Exceptions, Helpers, Constants)
← مستخدمة في جميع الطبقات
```

## 🔐 Data Safety

```
.env (SECRETS - محمي في .gitignore)
    ↓
.env.example (Template - في Git)
    ↓
flutter_dotenv (تحميل في main)
    ↓
Constants لا تحتوي على secrets
```

## ✅ Null Safety

**المشروع يستخدم Null Safety الكامل:**
- جميع المتغيرات صريحة (nullable أو non-nullable)
- لا توجد `dynamic` types
- استخدام `?` و `!` بحذر

## 🧪 Testing Structure (جاهز للإضافة)

```
test/
├── models/
│   └── product_test.dart
├── services/
│   └── supabase_service_test.dart
├── repositories/
│   └── product_repository_test.dart
└── screens/
    └── home_screen_test.dart
```

## 🚀 الخطوات التالية (المرحلة الثانية)

```
Phase 2 (بعد اعتماد البنية):
├── Riverpod State Management
├── Localization (AR/EN/FR)
├── Push Notifications
├── Real-time Chat
├── Payment Integration
└── Advanced Features
```

## 📈 Scalability

هذا الهيكل يدعم:
- ✅ نمو Team (سهل التعاون)
- ✅ نمو Features (هيكل منظم)
- ✅ Unit Testing (منفصل ومستقل)
- ✅ Code Reusability (مكتبات وواجهات واضحة)
- ✅ Performance Optimization (lazy loading, caching)

---

**هذا الهيكل يضمن مشروع احترافي وقابل للتطوير لسنوات قادمة!** ✨
