# 🚀 Kenza Hub - Setup & Deployment Guide

## المتطلبات الأساسية

### النظام
- **Windows/Mac/Linux** - أي نظام تشغيل
- **Flutter 3.10+** - تثبيت من [flutter.dev](https://flutter.dev)
- **Dart 3.0+** - يأتي مع Flutter
- **Git** - لإدارة النسخ

### لـ Android
- **Android SDK 21+**
- **Android Studio** (اختياري)
- **Gradle**

### لـ iOS
- **macOS 10.13+**
- **Xcode 13+**
- **CocoaPods**

### Supabase
- حساب مجاني على [supabase.com](https://supabase.com)
- Project name و URL و API keys

## 📥 الخطوة 1: تثبيت Flutter

### على Windows:
1. حمّل [Flutter SDK](https://flutter.dev/docs/get-started/install/windows)
2. فك الضغط في مجلد (مثل `C:\flutter`)
3. أضف المسار إلى PATH:
   ```
   C:\flutter\bin
   ```
4. افتح PowerShell وأكتب:
   ```bash
   flutter --version
   ```

### على Mac:
```bash
# باستخدام Homebrew
brew install flutter

# أو يدويّاً
cd ~/development
unzip ~/Downloads/flutter_macos_*.zip
export PATH="$PATH:~/development/flutter/bin"
```

### على Linux:
```bash
cd ~/development
tar xf ~/Downloads/flutter_linux_*.tar.xz
export PATH="$PATH:~/development/flutter/bin"
```

## 🔧 الخطوة 2: إعداد البيئة

```bash
# تحقق من التثبيت
flutter doctor

# سيظهر مثل هذا:
# ✓ Flutter
# ✓ Dart  
# ✓ Android SDK
# ✓ Chrome (if developing for web)
```

## 📱 الخطوة 3: استنساخ المستودع

```bash
git clone https://github.com/yourusername/kenza_hub_flutter.git
cd kenza_hub_flutter
```

## 🔑 الخطوة 4: إعداد Supabase

### أ. إنشاء Project على Supabase

1. اذهب إلى [supabase.com](https://supabase.com)
2. اضغط "New Project"
3. ملأ البيانات:
   - Project name: `kenza-hub`
   - Database password: احفظ كلمة المرور
   - Region: اختر الأقرب (مصر = Europe)

### ب. الحصول على Keys

```
Settings → API
```

انسخ:
- `Project URL` → `SUPABASE_URL`
- `anon public` → `SUPABASE_ANON_KEY`

### ج. إنشاء الجداول

نسخ كل SQL من `DATABASE_SCHEMA.md` وألصق في:
```
SQL Editor → New Query
```

ثم اضغط ▶ Execute

## 📝 الخطوة 5: إعداد ملف .env

```bash
# نسخ الملف
cp .env.example .env

# عدّل القيم
```

محتوى `.env`:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
APP_NAME=كينزا هب
DEBUG=true
```

## 📦 الخطوة 6: تثبيت Dependencies

```bash
# تحديث pub
flutter pub get

# تثبيت جميع packages
flutter pub upgrade
```

## 🏃 الخطوة 7: تشغيل التطبيق

### على محاكي Android:
```bash
# قائمة الأجهزة
flutter devices

# تشغيل
flutter run -d emulator-5554

# أو استخدم جهازك الفعلي
flutter run
```

### على جهاز فعلي (Android):
```bash
# تفعيل USB Debugging على الجهاز
# ثم:
flutter run
```

### على iOS:
```bash
flutter run -d <device-id>
```

### Development Mode:
```bash
# مع hot reload
flutter run

# بدون analytics
flutter run --no-verbose
```

## 🧪 الاختبار

```bash
# اختبر البناء
flutter test

# اختبر الـ format
flutter format --set-exit-if-changed .

# اختبر التحليل
flutter analyze
```

## 📦 البناء للإنتاج

### Android APK:
```bash
flutter build apk --release

# النتيجة:
# build/app/outputs/apk/release/app-release.apk
```

### Android Bundle (لـ Google Play):
```bash
flutter build appbundle --release

# النتيجة:
# build/app/outputs/bundle/release/app-release.aab
```

### iOS:
```bash
flutter build ios --release

# ثم استخدم Xcode لرفعه
```

## 🛠️ حل المشاكل الشائعة

### 1. `flutter doctor` يظهر أخطاء

```bash
# تحديث Flutter
flutter upgrade

# حل مشاكل Android
flutter doctor --android-licenses

# حل مشاكل Gradle
cd android && ./gradlew clean && cd ..
```

### 2. خطأ في رفع الصور

تأكد من:
- ✅ API keys صحيحة
- ✅ Supabase Storage bucket موجود
- ✅ Permissions صحيحة على Android:
  ```xml
  <!-- android/app/src/main/AndroidManifest.xml -->
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  ```

### 3. خطأ في الـ packages

```bash
# حذف cache
rm -rf pubspec.lock
rm -rf build/

# إعادة تثبيت
flutter pub get
```

## 🔐 الأمان

### قبل الإطلاق:

1. **تفعيل RLS على Supabase**
   ```sql
   ALTER TABLE products ENABLE ROW LEVEL SECURITY;
   ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
   ```

2. **إعداد API Rules**
   - حذف API key العام بعد الإنتاج
   - استخدم key مقيد للعمليات المحددة

3. **HTTPS فقط**
   - تأكد من استخدام HTTPS في جميع requests
   - قم بتعطيل HTTP

4. **Environment Variables**
   - لا تضع Keys في Git
   - استخدم .env بدلاً من hardcoding

## 📱 الإصدار

### سير العمل:

1. **تحديث version**
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2
   ```

2. **تحديث CHANGELOG**
   ```
   ## [1.0.1] - 2026-07-23
   - إصلاح أخطاء في رفع الصور
   - تحسينات الأداء
   ```

3. **البناء**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

4. **الرفع**
   - Google Play Console
   - Firebase Distribution (للاختبار)

## 🚀 الإطلاق

### Google Play Store:

1. إنشاء حساب Google Play Developer ($25 لمرة واحدة)
2. إنشاء app listing
3. تحميل signed APK/Bundle
4. ملء الوصف والصور
5. إرسال للمراجعة

## 📊 المراقبة

### تتبع الأخطاء (Sentry):

```dart
await Sentry.init(
  'YOUR_SENTRY_DSN',
  tracesSampleRate: 1.0,
);
```

### Analytics (Firebase):

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// Track events
analytics.logEvent(name: 'product_viewed');
```

## 🆘 الدعم والمساعدة

### المراجع:
- [Flutter Docs](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.io/docs)
- [Dart Docs](https://dart.dev/guides)

### المشاكل الشائعة:
- [Flutter Issues](https://github.com/flutter/flutter/issues)
- [Supabase Discussions](https://github.com/supabase/supabase/discussions)

---

**آخر تحديث:** July 2026
