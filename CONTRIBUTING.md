# 🤝 Contributing to Kenza Hub Flutter

**دليل المساهمة في مشروع Kenza Hub Flutter**

شكراً لاهتمامك بالمساهمة في Kenza Hub Flutter! 💪

---

## 📋 قبل البدء

اقرأ هذه الملفات أولاً:
1. **README.md** - نظرة عامة على المشروع
2. **SETUP.md** - كيفية تثبيت المشروع محلياً
3. **ARCHITECTURE.md** - شرح المعمارية
4. **PROJECT_ROADMAP.md** - مراحل التطوير
5. **MIGRATION_REPORT.md** - الحالة الحالية

---

## 🚀 Getting Started

### 1. Fork المشروع
```bash
# اضغط Fork على GitHub
# ثم Clone نسختك:
git clone https://github.com/yourusername/kenza_hub_flutter.git
cd kenza_hub_flutter
```

### 2. Setup Local Environment
```bash
# تثبيت dependencies
flutter pub get

# تحديث packages
flutter pub upgrade

# تحليل الكود
flutter analyze

# تشغيل التطبيق
flutter run
```

### 3. Create a Branch
```bash
# من main branch:
git checkout -b feature/your-feature-name
# أو
git checkout -b fix/issue-name
```

---

## 📝 Naming Conventions

### Branch Names
- **Features:** `feature/feature-name`
- **Bug Fixes:** `fix/bug-name`
- **Hotfixes:** `hotfix/urgent-fix`
- **Documentation:** `docs/doc-name`

**مثال:**
```
feature/add-chat-system
fix/image-upload-android
hotfix/critical-crash
docs/update-readme
```

### Commit Messages
```
[TYPE] Short description

Detailed explanation if needed.
- Bullet points for changes
- List impact areas

Fixes #123 (إذا كان يصلح issue)
```

**Types:**
- `feat:` - Feature جديدة
- `fix:` - Bug fix
- `refactor:` - Refactoring بدون تغيير functionality
- `test:` - Adding tests
- `docs:` - Documentation changes
- `style:` - Formatting (dart format)
- `chore:` - Dependencies update

**مثال:**
```
feat: Add real-time chat system

- Implement Supabase Realtime integration
- Add message model and repository
- Create chat UI screens
- Add notifications for new messages

Fixes #45
```

### File & Function Names
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Methods:** `camelCase`
- **Constants:** `CONSTANT_CASE`
- **Private:** `_leadingUnderscore`

---

## 💻 Code Standards

### Null Safety
✅ **MUST:** استخدم Null Safety 100%

```dart
// ❌ BAD - dynamic
var value = getSomething();

// ✅ GOOD - explicit type
String? value = getSomething();
String value = getSomethingOrDefault();
```

### Error Handling
✅ **MUST:** استخدم Failure classes بدل exceptions

```dart
// ❌ BAD
try {
  final user = await fetchUser();
  print(user);
} catch (e) {
  print('Error: $e');
}

// ✅ GOOD
final result = await userRepository.getUser(userId);
result.fold(
  (failure) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failure.message)),
  ),
  (user) => print('User: ${user.name}'),
);
```

### Result Type
✅ **MUST:** استخدم Result<T> للعمليات غير المتزامنة

```dart
// ❌ BAD - No type safety
Future<List<Product>> searchProducts(String query) async {
  try {
    // ...
    return products;
  } catch (e) {
    throw Exception('Search failed');
  }
}

// ✅ GOOD - Type safe
Future<Result<List<Product>>> searchProducts(String query) async {
  try {
    // ...
    return Success(products);
  } catch (e) {
    return Failure(SearchFailure(message: e.toString()));
  }
}
```

### Documentation
✅ **SHOULD:** كل class/method عام يجب أن يكون موثق

```dart
/// Searches for products matching the query.
///
/// [query] - The search term
/// [limit] - Maximum number of results (default: 20)
/// 
/// Returns [Result<List<Product>>]
/// - Success: List of matching products
/// - Failure: SearchFailure with error message
Future<Result<List<Product>>> searchProducts(
  String query, {
  int limit = 20,
}) async {
  // ...
}
```

### Testing
✅ **SHOULD:** أضف tests مع features جديدة

```dart
// في test/
void main() {
  group('ProductRepository', () {
    test('searchProducts returns list of products', () async {
      final result = await repository.searchProducts('test');
      expect(result.isSuccess, true);
    });

    test('searchProducts returns failure on error', () async {
      final result = await repository.searchProducts('');
      expect(result.isFailure, true);
    });
  });
}
```

---

## 📁 Folder Structure

إذا أضفت files جديدة:

```
lib/
├── core/              - Shared utilities
├── config/            - App configuration
├── models/            - Data models
├── services/          - Business logic
├── repositories/      - Data access layer
├── storage/           - Local storage
├── network/           - Network utilities
├── screens/           - UI screens
└── widgets/           - Reusable components (if added)
```

---

## 🧪 Testing

### Before Commit
```bash
# تحليل
flutter analyze

# تنسيق
dart format lib/

# Tests
flutter test

# Build
flutter build apk --release
```

### Add Tests
```dart
// في test/repositories/product_repository_test.dart
void main() {
  group('ProductRepository', () {
    late ProductRepository repository;

    setUp(() {
      repository = ProductRepository(
        supabaseService: MockSupabaseService(),
      );
    });

    test('method returns expected result', () async {
      // Arrange
      final expectedResult = [...];
      
      // Act
      final result = await repository.searchProducts('query');
      
      // Assert
      expect(result.isSuccess, true);
      result.fold(
        (_) => fail('Expected success'),
        (data) => expect(data, expectedResult),
      );
    });
  });
}
```

---

## 📤 Submitting a Pull Request

### 1. Push Your Branch
```bash
git push origin feature/your-feature-name
```

### 2. Create Pull Request
- اذهب إلى GitHub
- اضغط "Compare & pull request"
- ملأ البيانات:

```markdown
## Description
ما الذي تم تغييره؟

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change

## Related Issue
Fixes #123

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] No hardcoded secrets
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings
```

### 3. Code Review
- الفريق سيراجع الكود
- قد تكون هناك تعليقات
- عدّل حسب الملاحظات

### 4. Merge
- عند الموافقة، الـ PR سيُدمج
- شكراً! 🎉

---

## 🚫 Rules

### Must Follow
- ✅ 100% Null Safety
- ✅ استخدام Failure classes
- ✅ استخدام Result<T>
- ✅ بدون hardcoded secrets
- ✅ documentation for public APIs
- ✅ Tests for new features
- ✅ No breaking changes (إلا إذا approved)

### Best Practices
- ✅ Keep methods small
- ✅ Single responsibility
- ✅ DRY (Don't Repeat Yourself)
- ✅ SOLID principles
- ✅ Clean code

### Absolutely NOT
- ❌ استخدام `dynamic`
- ❌ Empty catch blocks
- ❌ Hardcoded values
- ❌ Commented code (احذفه)
- ❌ Secrets في الكود
- ❌ Breaking changes بدون approval

---

## 🐛 Reporting Bugs

### إنشاء Issue
1. اذهب إلى GitHub Issues
2. اضغط "New issue"
3. ملأ البيانات:

```markdown
## Description
ما المشكلة؟

## Steps to Reproduce
1. خطوة 1
2. خطوة 2
3. خطوة 3

## Expected Behavior
ما الذي يجب أن يحدث؟

## Actual Behavior
ما الذي يحدث فعلاً؟

## Screenshots (if applicable)
صور للمشكلة

## Environment
- Device: Android/iOS
- OS Version: 
- App Version:

## Additional Context
معلومات إضافية
```

---

## 💡 Feature Requests

### إنشاء Feature Request
1. اذهب إلى GitHub Issues
2. اضغط "New issue"
3. اختر "Feature request"
4. ملأ البيانات:

```markdown
## Description
ما الـ feature المطلوب؟

## Use Case
لماذا هذا الـ feature مهم؟

## Proposed Solution
كيف يجب أن يعمل؟

## Alternatives
هناك بدائل؟

## Additional Context
معلومات إضافية
```

---

## 📞 Getting Help

### Resources
- 📚 [ARCHITECTURE.md](ARCHITECTURE.md) - شرح المعمارية
- 🗺️ [PROJECT_ROADMAP.md](PROJECT_ROADMAP.md) - مراحل التطوير
- 📋 [MIGRATION_REPORT.md](MIGRATION_REPORT.md) - الحالة الحالية
- 📖 [Dart Documentation](https://dart.dev)
- 🐦 [Flutter Documentation](https://flutter.dev)

### Discussion
- GitHub Issues
- GitHub Discussions (إذا كان موجود)
- Discord/Slack (إذا كان موجود)

---

## 🎓 Development Phases

المشروع مقسم إلى phases:

**Phase 1:** Foundation (Current) ✅  
**Phase 2:** Authentication + Core Features ⏳  
**Phase 3:** Product Publishing ⏳  
**Phase 4:** Chat System ⏳  
**Phase 5:** Orders & Escrow ⏳  
**Phase 6:** Payments ⏳  
**Phase 7:** Beta Testing ⏳  
**Phase 8:** Production Launch ⏳  

إذا تريد المساهمة في phase معين، فضلاً اطلب في GitHub!

---

## ✨ Best Contributors Get

- 🌟 Recognition في README
- 👏 Credit في Changelog
- 🎁 Special perks (يحتمل)
- 🚀 Priority review

---

## 📝 Changelog

أي تغيير يجب أن يُوثق في:
- Commit message واضح
- PR description مفصلة
- CHANGELOG.md (إذا موجود)

---

## 🎯 Code of Conduct

- احترم جميع المساهمين
- كن محترماً في التعليقات
- لا harassment أو discrimination
- ركز على الكود وليس الشخص

---

## 🙏 Thank You!

شكراً لمساهمتك في Kenza Hub Flutter!

بدونكم، ما كان هذا المشروع ممكن. 💙

---

**Ready to contribute? Let's build something great together!** 🚀
